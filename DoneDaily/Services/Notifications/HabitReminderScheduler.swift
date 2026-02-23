import Foundation
import UserNotifications

protocol NotificationCenterScheduling {
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: NotificationCenterScheduling {}

enum HabitReminderScheduler {
    @discardableResult
    static func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func scheduleIfEnabled(
        for habit: Habit,
        center: NotificationCenterScheduling = UNUserNotificationCenter.current()
    ) async {
        await cancel(for: habit, center: center)

        guard habit.reminderEnabled, habit.isActive else { return }
        let weekdays = habit.reminderWeekdays
        guard !weekdays.isEmpty else { return }

        for request in buildRequests(for: habit, weekdays: weekdays) {
            do {
                try await center.add(request)
            } catch {
                AppErrorReporter.report("Failed to schedule reminder: \(error)")
            }
        }
    }

    static func cancel(
        for habit: Habit,
        center: NotificationCenterScheduling = UNUserNotificationCenter.current()
    ) async {
        let identifiers = (1...7).map { notificationIdentifier(for: habit.id, weekday: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    static func buildRequests(for habit: Habit, weekdays: Set<Int>? = nil) -> [UNNotificationRequest] {
        let selectedWeekdays = weekdays ?? reminderWeekdays(for: habit)
        return selectedWeekdays
            .filter { (1...7).contains($0) }
            .sorted()
            .map { weekday in
                var components = DateComponents()
                components.weekday = weekday
                components.hour = habit.reminderHour
                components.minute = habit.reminderMinute

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let content = UNMutableNotificationContent()
                content.title = habit.name
                content.body = reminderBody(for: habit)
                content.sound = .default

                let identifier = notificationIdentifier(for: habit.id, weekday: weekday)
                return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            }
    }

    static func notificationIdentifier(for habitID: UUID, weekday: Int) -> String {
        "habit-reminder-\(habitID.uuidString)-\(weekday)"
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    private static func reminderWeekdays(for habit: Habit) -> Set<Int> {
        switch habit.reminderPattern {
        case .weekdays:
            return habit.reminderWeekdays
        case .daily, .gentleEvening, .afterMissedDays:
            return Set(1...7)
        }
    }

    private static func reminderBody(for habit: Habit) -> String {
        if habit.trackingType == .count {
            let progress = habit.dailyProgress(on: .now)
            let remaining = max(0, habit.dailyTarget - progress)
            if remaining > 0 {
                return "Noch \(remaining) bis zum Tagesziel."
            }
        }

        switch habit.reminderPattern {
        case .daily:
            return "Zeit für deinen Habit-Check-in."
        case .weekdays:
            return "Kurzer Werktag-Check-in für \(habit.name)."
        case .gentleEvening:
            return "Sanfte Erinnerung: ein kleiner Check-in am Abend reicht."
        case .afterMissedDays:
            return "Wenn du \(habit.reminderMissedDaysThreshold) Tage auslässt, hilft dieser Nudge."
        }
    }
}
