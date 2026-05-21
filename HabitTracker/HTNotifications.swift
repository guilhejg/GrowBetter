import Foundation
import UserNotifications

enum HTNotifications {

    // MARK: - Permission

    static func requestPermissionIfNeeded() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }

            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error {
                    print("Notification permission error:", error)
                }
            }
        }
    }

    // MARK: - Daily Reminders (Multiple Times)

    static func scheduleDailyReminders(
        times: [(hour: Int, minute: Int)],
        title: String = "Hora de marcar! ✨",
        body: String = "Marque seus hábitos hoje e não perca sua sequência!"
    ) {
        let center = UNUserNotificationCenter.current()

        // Remove notificações antigas desse grupo
        let identifiers = times.map { "ht_daily_\($0.hour)_\($0.minute)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        for time in times {

            var components = DateComponents()
            components.hour = time.hour
            components.minute = time.minute

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )

            let identifier = "ht_daily_\(time.hour)_\(time.minute)"

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }
}
