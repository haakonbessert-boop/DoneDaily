import Foundation
import UserNotifications

enum HabitReminderScheduler {
    static func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func scheduleIfEnabled(for habit: Habit) async {
        await cancel(for: habit)

        guard habit.reminderEnabled else { return }
        let weekdays = habit.reminderWeekdays
        guard !weekdays.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        for weekday in weekdays {
            var components = DateComponents()
            components.weekday = weekday
            components.hour = habit.reminderHour
            components.minute = habit.reminderMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = habit.name
            content.body = "Zeit für deinen Habit-Check-in."
            content.sound = .default

            let identifier = notificationIdentifier(for: habit.id, weekday: weekday)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                assertionFailure("Failed to schedule reminder: \(error)")
            }
        }
    }

    static func cancel(for habit: Habit) async {
        let identifiers = (1...7).map { notificationIdentifier(for: habit.id, weekday: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func notificationIdentifier(for habitID: UUID, weekday: Int) -> String {
        "habit-reminder-\(habitID.uuidString)-\(weekday)"
    }
}
