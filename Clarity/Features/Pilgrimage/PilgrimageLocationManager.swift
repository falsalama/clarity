import Foundation
import Combine
import CoreLocation

@MainActor
final class PilgrimageLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    enum State {
        case idle
        case denied
        case unavailable
        case locating
        case located(CLLocation)
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
