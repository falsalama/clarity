import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    private override init() {
        super.init()
        center.delegate = self
    }

    private let center = UNUserNotificationCenter.current()

    private enum IDs {
        static let testOnce = "clarity_nudge_test_once"
        static let dailyPrefix = "clarity_nudge_daily_"
    }

    private enum Keys {
        static let enabled = "daily_nudge_enabled"
        static let hour = "daily_nudge_hour"
        static let minute = "daily_nudge_minute"
        static let seed = "daily_nudge_seed"
    }

    private let schedulingHorizonDays = 90

    private let dailyNudgeMessages: [(title: String, body: String)] = [
        (
            title: "Clarity",
            body: "A few minutes of practice can change the tone of a whole day."
        ),
        (
            title: "Clarity",
            body: "Return to stillness. Practice when you are ready."
        ),
        (
            title: "Clarity",
            body: "Meditation builds steadiness slowly. Small daily returns matter."
        ),
        (
            title: "Clarity",
            body: "Completed Meditation Zone sessions can count toward Apple Health mindful minutes."
        ),
        (
            title: "Clarity",
            body: "Continuity is built by returning."
        ),
        (
            title: "Clarity",
            body: "A short sit is enough. Clarity grows through repetition, not force."
        )
    ]

    // MARK: - Permission

    func requestPermissionIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    // MARK: - Scheduling

    func scheduleTestIn(seconds: TimeInterval, title: String, body: String) async {
        guard await requestPermissionIfNeeded() else { return }

        center.removePendingNotificationRequests(withIdentifiers: [IDs.testOnce])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(5, seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: IDs.testOnce,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            // best-effort
        }
    }

    /// Schedules a rolling set of one-off daily notifications so the message can vary.
    func scheduleDaily(hour: Int, minute: Int) async {
        guard await requestPermissionIfNeeded() else { return }

        let clampedHour = max(0, min(23, hour))
        let clampedMinute = max(0, min(59, minute))

        UserDefaults.standard.set(clampedHour, forKey: Keys.hour)
        UserDefaults.standard.set(clampedMinute, forKey: Keys.minute)

        let seed = sequenceSeed()

        await cancelDaily()

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        for offset in 0..<schedulingHorizonDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else {
                continue
            }

            var comps = calendar.dateComponents([.year, .month, .day], from: day)
            comps.hour = clampedHour
            comps.minute = clampedMinute

            guard let fireDate = calendar.date(from: comps) else { continue }
            guard fireDate > now.addingTimeInterval(5) else { continue }

            let messageIndex = (seed + offset) % dailyNudgeMessages.count
            let chosen = dailyNudgeMessages[messageIndex]

            let content = UNMutableNotificationContent()
            content.title = chosen.title
            content.body = chosen.body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let identifier = IDs.dailyPrefix + requestDateKey(for: fireDate)

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                // best-effort
            }
        }
    }

    /// Rebuilds the rolling schedule if reminders are enabled.
    func refreshDailyScheduleIfEnabled(defaultHour: Int = 10, defaultMinute: Int = 0) async {
        guard UserDefaults.standard.bool(forKey: Keys.enabled) else { return }

        let hour: Int
        let minute: Int

        if UserDefaults.standard.object(forKey: Keys.hour) != nil {
            hour = UserDefaults.standard.integer(forKey: Keys.hour)
        } else {
            hour = defaultHour
        }

        if UserDefaults.standard.object(forKey: Keys.minute) != nil {
            minute = UserDefaults.standard.integer(forKey: Keys.minute)
        } else {
            minute = defaultMinute
        }

        await scheduleDaily(hour: hour, minute: minute)
    }

    func cancelDaily() async {
        let ids = await pendingDailyIdentifiers()
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelAllClarityNudges() async {
        await cancelDaily()
        center.removePendingNotificationRequests(withIdentifiers: [IDs.testOnce])
    }

    // MARK: - Foreground presentation

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    // MARK: - Settings

    func openSystemSettings() {
#if canImport(UIKit)
        let app = UIApplication.shared
        if #available(iOS 16.0, *) {
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                app.open(url, options: [:], completionHandler: nil)
                return
            }
        }
        if let url = URL(string: UIApplication.openSettingsURLString) {
            app.open(url, options: [:], completionHandler: nil)
        }
#endif
    }

    // MARK: - Helpers

    private func sequenceSeed() -> Int {
        if let stored = UserDefaults.standard.object(forKey: Keys.seed) as? Int {
            return stored
        }

        let newSeed = Int.random(in: 0..<max(1, dailyNudgeMessages.count))
        UserDefaults.standard.set(newSeed, forKey: Keys.seed)
        return newSeed
    }

    private func requestDateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.timeZone = .current
        f.dateFormat = "yyyyMMdd"
        return f.string(from: date)
    }

    private func pendingDailyIdentifiers() async -> [String] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let ids = requests
                    .map(\.identifier)
                    .filter { $0.hasPrefix(IDs.dailyPrefix) }
                continuation.resume(returning: ids)
            }
        }
    }
}
