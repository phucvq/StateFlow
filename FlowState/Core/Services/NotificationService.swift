import Foundation
import UserNotifications

// NSObject subclass required to conform to UNUserNotificationCenterDelegate.
final class NotificationService: NSObject {

    static let shared = NotificationService()

    override private init() {
        super.init()
        // Register as delegate so banners show even when the app is in the foreground.
        // Without this, iOS silently drops banners while the app is active.
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Schedule Session End (work timer complete)
    func scheduleSessionEnd(in duration: TimeInterval, taskName: String? = nil) {
        cancelAll()

        let content = UNMutableNotificationContent()
        content.title = L10n.notifSessionEndTitle
        content.body = taskName != nil
            ? String(format: L10n.notifSessionEndBodyTask, taskName!)
            : L10n.notifSessionEndBody
        content.sound = .default         // system default chime
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, duration), repeats: false)
        let request = UNNotificationRequest(identifier: "session-end", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("[Notification] session-end: \(error)") }
        }
    }

    // MARK: - Schedule Break End (break timer complete)
    func scheduleBreakEnd(in duration: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = L10n.notifBreakEndTitle
        content.body = L10n.notifBreakEndBody
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, duration), repeats: false)
        let request = UNNotificationRequest(identifier: "break-end", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("[Notification] break-end: \(error)") }
        }
    }

    // MARK: - Schedule Break Reminder
    func scheduleBreakReminder(workedMinutes: Int, delay: TimeInterval = 300) {
        let content = UNMutableNotificationContent()
        content.title = L10n.notifBreakReminderTitle
        content.body = String(format: L10n.notifBreakReminderBody, workedMinutes)
        content.sound = .default
        content.interruptionLevel = .passive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: "break-reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("[Notification] break-reminder: \(error)") }
        }
    }

    // MARK: - Cancel
    func cancelSessionNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["session-end", "break-end", "break-reminder"]
        )
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate
// Returning [.banner, .sound, .list] here makes iOS show the banner AND play the
// sound while the app is in the foreground — the default behaviour suppresses both.
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
