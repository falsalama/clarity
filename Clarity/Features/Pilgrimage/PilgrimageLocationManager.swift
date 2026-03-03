import Foundation
import Combine
import CoreLocation

@MainActor
final class PilgrimageLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    enum State: Equatable {
        case idle
        case denied
        case unavailable
        case locating
        case located(CLLocation)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                 (.denied, .denied),
                 (.unavailable, .unavailable),
                 (.locating, .locating):
                return true
            case (.located, .located):
                // UI doesn’t need to compare coordinates for equality here.
                return true
            default:
                return false
            }
        }
    }

    @Published private(set) var state: State = .idle

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Public entry-point from UI. Does the heavy checks off-main.
    func requestOneShotLocation() {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let servicesEnabled = CLLocationManager.locationServicesEnabled()

            // Swift 6: `manager` is main-actor isolated, so read it on MainActor.
            let status: CLAuthorizationStatus = await MainActor.run {
                self.manager.authorizationStatus
            }

            await self.handleRequest(servicesEnabled: servicesEnabled, status: status)
        }
    }

    @MainActor
    private func handleRequest(servicesEnabled: Bool, status: CLAuthorizationStatus) {
        guard servicesEnabled else {
            state = .unavailable
            return
        }

        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .restricted, .denied:
            state = .denied

        case .authorizedAlways, .authorizedWhenInUse:
            state = .locating
            manager.requestLocation()

        @unknown default:
            state = .unavailable
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Delegate callbacks are fine on main; just re-run request flow.
        requestOneShotLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        state = .located(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        state = .unavailable
    }
}
