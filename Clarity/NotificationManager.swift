// NotificationManager.swift

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
        center.delegate = self // show banners while app is open (foreground)
    }

    private let center = UNUserNotificationCenter.current()

    private enum IDs {
        static let testOnce = "clarity_nudge_test_once"
        static let daily = "clarity_nudge_daily"
    }

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

    /// Returns true if notifications are authorised (or provisionally authorised).
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

    /// One-time test notification after N seconds (useful to confirm delivery immediately).
    func scheduleTestIn(seconds: TimeInterval, title: String, body: String) async {
        guard await requestPermissionIfNeeded() else { return }

        center.removePendingNotificationRequests(withIdentifiers: [IDs.testOnce])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: IDs.testOnce, content: content, trigger: trigger)

        do { try await center.add(request) } catch { /* best-effort */ }
    }

    /// Repeating daily notification at the specified local time (hour/minute).
    /// Replaces any existing Clarity daily request.
    func scheduleDaily(hour: Int, minute: Int, title: String? = nil, body: String? = nil) async {
        guard await requestPermissionIfNeeded() else { return }

        await cancelDaily()

        let messages = dailyNudgeMessages
        let chosen = messages.randomElement() ?? (
            title: "Clarity",
            body: "Return to practice."
        )

        let content = UNMutableNotificationContent()
        content.title = title ?? chosen.title
        content.body = body ?? chosen.body
        content.sound = .default

        var comps = DateComponents()
        comps.hour = max(0, min(23, hour))
        comps.minute = max(0, min(59, minute))

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: IDs.daily, content: content, trigger: trigger)

        do { try await center.add(request) } catch { /* best-effort */ }
    }

    func cancelDaily() async {
        center.removePendingNotificationRequests(withIdentifiers: [IDs.daily])
    }

    func cancelAllClarityNudges() async {
        center.removePendingNotificationRequests(withIdentifiers: [IDs.testOnce, IDs.daily])
    }

    // MARK: - Foreground presentation

    /// If the app is open, still show the banner/sound (otherwise it can look like “nothing happened”).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    // MARK: - Settings

    /// Opens the system Notifications settings for this app if possible, otherwise the app settings page.
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
}

