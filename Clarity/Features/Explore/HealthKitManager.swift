import Foundation
import Combine
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    enum ManagerError: LocalizedError {
        case unavailable
        case authorizationNotGranted

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Health data is not available on this device."
            case .authorizationNotGranted:
                return "Health access was not granted."
            }
        }
    }

    private enum Keys {
        static let writeMindfulSessionsEnabled = "healthkit.writeMindfulSessionsEnabled"
    }

    @Published private(set) var isAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    @Published private(set) var authorizationRequestStatus: HKAuthorizationRequestStatus = .unknown
    @Published private(set) var mindfulShareAuthorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published private(set) var isBusy = false
    @Published private(set) var lastErrorMessage: String?

    @Published var writeMindfulSessionsEnabled: Bool {
        didSet {
            defaults.set(writeMindfulSessionsEnabled, forKey: Keys.writeMindfulSessionsEnabled)
        }
    }

    private let store = HKHealthStore()
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.writeMindfulSessionsEnabled =
            defaults.object(forKey: Keys.writeMindfulSessionsEnabled) as? Bool ?? true

    }

    func refreshAuthorizationState() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
        lastErrorMessage = nil

        guard isAvailable else {
            authorizationRequestStatus = .unknown
            mindfulShareAuthorizationStatus = .notDetermined
            return
        }

        mindfulShareAuthorizationStatus = store.authorizationStatus(for: Self.mindfulSessionType)

        let store = self.store

        store.getRequestStatusForAuthorization(
            toShare: Self.shareTypes,
            read: Self.readTypes
        ) { [weak self] status, error in            let errorMessage = error?.localizedDescription

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                if let errorMessage {
                    self.lastErrorMessage = errorMessage
                    return
                }

                self.authorizationRequestStatus = status
            }
        }
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAvailable = false
            lastErrorMessage = ManagerError.unavailable.localizedDescription
            return
        }

        isBusy = true
        lastErrorMessage = nil
        defer { isBusy = false }

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                store.requestAuthorization(
                    toShare: Self.shareTypes,
                    read: Self.readTypes
                ) { success, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard success else {
                        continuation.resume(throwing: ManagerError.authorizationNotGranted)
                        return
                    }

                    continuation.resume(returning: ())
                }
            }

            refreshAuthorizationState()
        } catch {
            lastErrorMessage = error.localizedDescription
            refreshAuthorizationState()
        }
    }
    func saveMindfulSession(start: Date, end: Date) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            lastErrorMessage = ManagerError.unavailable.localizedDescription
            return false
        }

        guard writeMindfulSessionsEnabled else {
            return false
        }

        guard mindfulShareAuthorizationStatus == .sharingAuthorized else {
            lastErrorMessage = "Apple Health write access has not been granted."
            return false
        }

        let sample = HKCategorySample(
            type: Self.mindfulSessionType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                store.save(sample) { success, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    if success {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: ManagerError.authorizationNotGranted)
                    }
                }
            }

            lastErrorMessage = nil
            return true
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }
    // MARK: - Requested types

    static let mindfulSessionType: HKCategoryType = {
        guard let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            fatalError("Failed to create mindfulSession type.")
        }
        return type
    }()

    private static let sleepAnalysisType: HKCategoryType = {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            fatalError("Failed to create sleepAnalysis type.")
        }
        return type
    }()

    private static let stepCountType: HKQuantityType = {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("Failed to create stepCount type.")
        }
        return type
    }()

    private static let heartRateType: HKQuantityType = {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            fatalError("Failed to create heartRate type.")
        }
        return type
    }()

    static let shareTypes: Set<HKSampleType> = [
        mindfulSessionType
    ]

    static let readTypes: Set<HKObjectType> = [
        mindfulSessionType,
        sleepAnalysisType,
        stepCountType,
        heartRateType
    ]
}
