import Foundation

enum HabitInputValidator {
    static func canSave(name: String, reminderEnabled: Bool, reminderWeekdays: Set<Int>) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasReminderDay = !reminderEnabled || !reminderWeekdays.isEmpty
        return !trimmedName.isEmpty && hasReminderDay
    }

    static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
