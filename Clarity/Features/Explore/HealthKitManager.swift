import Foundation
import Combine
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    struct PatternInsight: Identifiable, Hashable {
        let id: String
        let title: String
        let detail: String
    }

    struct PatternSummary: Equatable {
        let averageSleepHours: Double?
        let averageDailySteps: Double?
        let averageHeartRate: Double?
        let averageMindfulMinutes: Double?
        let sampleDays: Int
    }

    struct PatternSnapshot: Equatable {
        let summary: PatternSummary
        let insights: [PatternInsight]
    }

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
    @Published private(set) var isLoadingPatterns = false
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var patternSnapshot: PatternSnapshot?

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

    func refreshPatterns(windowDays: Int = 14) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            patternSnapshot = nil
            return
        }

        isLoadingPatterns = true
        defer { isLoadingPatterns = false }

        let calendar = Calendar.autoupdatingCurrent
        let endDate = Date()
        let startDate =
            calendar.date(byAdding: .day, value: -(max(windowDays, 7) - 1), to: calendar.startOfDay(for: endDate))
            ?? calendar.startOfDay(for: endDate)

        do {
            async let mindfulSamples: [HKCategorySample] = fetchCategorySamples(
                type: Self.mindfulSessionType,
                start: startDate,
                end: endDate
            )
            async let sleepSamples: [HKCategorySample] = fetchCategorySamples(
                type: Self.sleepAnalysisType,
                start: startDate,
                end: endDate
            )
            async let stepSamples: [HKQuantitySample] = fetchQuantitySamples(
                type: Self.stepCountType,
                start: startDate,
                end: endDate
            )
            async let heartSamples: [HKQuantitySample] = fetchQuantitySamples(
                type: Self.heartRateType,
                start: startDate,
                end: endDate
            )

            let snapshot = buildPatternSnapshot(
                mindfulSamples: try await mindfulSamples,
                sleepSamples: try await sleepSamples,
                stepSamples: try await stepSamples,
                heartRateSamples: try await heartSamples,
                startDate: startDate,
                endDate: endDate,
                calendar: calendar
            )

            patternSnapshot = snapshot
        } catch {
            lastErrorMessage = error.localizedDescription
            patternSnapshot = nil
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

    private struct DailyAggregate {
        let day: Date
        var sleepHours: Double = 0
        var stepCount: Double = 0
        var heartRateValues: [Double] = []
        var mindfulMinutes: Double = 0

        var averageHeartRate: Double? {
            guard heartRateValues.isEmpty == false else { return nil }
            return heartRateValues.reduce(0, +) / Double(heartRateValues.count)
        }
    }

    private func fetchCategorySamples(
        type: HKCategoryType,
        start: Date,
        end: Date
    ) async throws -> [HKCategorySample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }

            store.execute(query)
        }
    }

    private func fetchQuantitySamples(
        type: HKQuantityType,
        start: Date,
        end: Date
    ) async throws -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
            }

            store.execute(query)
        }
    }

    private func buildPatternSnapshot(
        mindfulSamples: [HKCategorySample],
        sleepSamples: [HKCategorySample],
        stepSamples: [HKQuantitySample],
        heartRateSamples: [HKQuantitySample],
        startDate: Date,
        endDate: Date,
        calendar: Calendar
    ) -> PatternSnapshot? {
        var days: [Date: DailyAggregate] = [:]
        var cursor = calendar.startOfDay(for: startDate)
        let finalDay = calendar.startOfDay(for: endDate)

        while cursor <= finalDay {
            days[cursor] = DailyAggregate(day: cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        for sample in mindfulSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            guard var aggregate = days[day] else { continue }
            aggregate.mindfulMinutes += sample.endDate.timeIntervalSince(sample.startDate) / 60
            days[day] = aggregate
        }

        for sample in sleepSamples where isAsleepSample(sample) {
            let day = calendar.startOfDay(for: sample.endDate)
            guard var aggregate = days[day] else { continue }
            aggregate.sleepHours += sample.endDate.timeIntervalSince(sample.startDate) / 3600
            days[day] = aggregate
        }

        let stepUnit = HKUnit.count()
        for sample in stepSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            guard var aggregate = days[day] else { continue }
            aggregate.stepCount += sample.quantity.doubleValue(for: stepUnit)
            days[day] = aggregate
        }

        let heartUnit = HKUnit.count().unitDivided(by: .minute())
        for sample in heartRateSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            guard var aggregate = days[day] else { continue }
            aggregate.heartRateValues.append(sample.quantity.doubleValue(for: heartUnit))
            days[day] = aggregate
        }

        let aggregates = days.values.sorted { $0.day < $1.day }
        let sampleDays = aggregates.filter {
            $0.sleepHours > 0 || $0.stepCount > 0 || $0.mindfulMinutes > 0 || $0.averageHeartRate != nil
        }

        guard sampleDays.isEmpty == false else { return nil }

        let summary = PatternSummary(
            averageSleepHours: average(sampleDays.map(\.sleepHours).filter { $0 > 0 }),
            averageDailySteps: average(sampleDays.map(\.stepCount).filter { $0 > 0 }),
            averageHeartRate: average(sampleDays.compactMap(\.averageHeartRate)),
            averageMindfulMinutes: average(sampleDays.map(\.mindfulMinutes).filter { $0 > 0 }),
            sampleDays: sampleDays.count
        )

        return PatternSnapshot(
            summary: summary,
            insights: patternInsights(from: aggregates)
        )
    }

    private func patternInsights(from days: [DailyAggregate]) -> [PatternInsight] {
        let higherMindfulDays = days.filter { $0.mindfulMinutes >= 10 }
        let lowerMindfulDays = days.filter { $0.mindfulMinutes > 0 && $0.mindfulMinutes < 10 }
        var insights: [PatternInsight] = []

        if let highSleep = average(higherMindfulDays.map(\.sleepHours).filter { $0 > 0 }),
           let lowSleep = average(lowerMindfulDays.map(\.sleepHours).filter { $0 > 0 }),
           higherMindfulDays.count >= 3,
           lowerMindfulDays.count >= 3,
           highSleep - lowSleep >= 0.4 {
            insights.append(
                PatternInsight(
                    id: "sleep-vs-mindful",
                    title: "Sleep tends to run longer on steadier practice days",
                    detail: "Over recent days, 10+ mindful minutes tends to coincide with about \(formattedHours(highSleep - lowSleep)) more sleep that night."
                )
            )
        }

        if let highHeart = average(higherMindfulDays.compactMap(\.averageHeartRate)),
           let lowHeart = average(lowerMindfulDays.compactMap(\.averageHeartRate)),
           higherMindfulDays.count >= 3,
           lowerMindfulDays.count >= 3,
           lowHeart - highHeart >= 3 {
            insights.append(
                PatternInsight(
                    id: "heart-vs-mindful",
                    title: "Higher-mindfulness days look calmer in heart-rate terms",
                    detail: "Average heart rate tends to sit about \(Int((lowHeart - highHeart).rounded())) bpm lower on days with 10+ mindful minutes."
                )
            )
        }

        if let highSteps = average(higherMindfulDays.map(\.stepCount).filter { $0 > 0 }),
           let lowSteps = average(lowerMindfulDays.map(\.stepCount).filter { $0 > 0 }),
           higherMindfulDays.count >= 3,
           lowerMindfulDays.count >= 3,
           highSteps - lowSteps >= 1000 {
            insights.append(
                PatternInsight(
                    id: "steps-vs-mindful",
                    title: "Movement and mindful time are tending to travel together",
                    detail: "Days with 10+ mindful minutes are also averaging about \(Int((highSteps - lowSteps).rounded())) more steps."
                )
            )
        }

        if insights.isEmpty, days.contains(where: { $0.mindfulMinutes > 0 }) {
            insights.append(
                PatternInsight(
                    id: "not-enough-signal",
                    title: "Patterns are still forming",
                    detail: "Clarity needs a little more repeated mindful time before sleep, heart-rate trends, and movement start to compare cleanly."
                )
            )
        }

        return insights
    }

    private func average(_ values: [Double]) -> Double? {
        guard values.isEmpty == false else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func isAsleepSample(_ sample: HKCategorySample) -> Bool {
        if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
            return false
        }

        if #available(iOS 16.0, macOS 13.0, *) {
            if sample.value == HKCategoryValueSleepAnalysis.awake.rawValue {
                return false
            }
        }

        return true
    }

    private func formattedHours(_ value: Double) -> String {
        let hours = Int(value)
        let minutes = Int(((value - Double(hours)) * 60).rounded())

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }
}
