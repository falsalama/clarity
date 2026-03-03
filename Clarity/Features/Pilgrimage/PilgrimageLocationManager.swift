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
                // Treat any two .located states as equal for onChange comparisons.
                // We don't compare CLLocation (not Equatable) and we don't need to
                // distinguish different coordinates for this UI trigger.
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

    func requestOneShotLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            state = .unavailable
            return
        }

        switch manager.authorizationStatus {
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

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            requestOneShotLocation()
        case .restricted, .denied:
            state = .denied
        case .notDetermined:
            state = .idle
        @unknown default:
            state = .unavailable
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        state = .located(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        state = .unavailable
    }
}
