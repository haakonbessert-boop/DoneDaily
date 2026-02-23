import Foundation
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorRawValue: String
    var targetPerWeek: Int
    var createdAt: Date
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var reminderWeekdaysRaw: String

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        color: HabitColor,
        targetPerWeek: Int,
        reminderEnabled: Bool = false,
        reminderHour: Int = 20,
        reminderMinute: Int = 0,
        reminderWeekdays: Set<Int> = Set(1...7),
        createdAt: Date = .now,
        logs: [HabitLog] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorRawValue = color.rawValue
        self.targetPerWeek = max(1, targetPerWeek)
        self.createdAt = createdAt
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.reminderWeekdaysRaw = Habit.encodeWeekdays(reminderWeekdays)
        self.logs = logs
    }

    var color: HabitColor {
        get { HabitColor(rawValue: colorRawValue) ?? .blue }
        set { colorRawValue = newValue.rawValue }
    }

    var reminderWeekdays: Set<Int> {
        get { Habit.decodeWeekdays(reminderWeekdaysRaw) }
        set { reminderWeekdaysRaw = Habit.encodeWeekdays(newValue) }
    }

    func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        logs.contains { log in
            calendar.isDate(log.date, inSameDayAs: date) && log.completed
        }
    }

    func completedThisWeek(referenceDate: Date = .now, weekStart: Int = 2, calendar: Calendar = .current) -> Int {
        guard let week = Self.weekInterval(containing: referenceDate, weekStart: weekStart, calendar: calendar) else {
            return 0
        }

        return logs.filter { log in
            log.completed && week.contains(log.date)
        }.count
    }

    func completedCount(inLast days: Int, referenceDate: Date = .now, calendar: Calendar = .current) -> Int {
        guard days > 0 else { return 0 }
        let end = calendar.startOfDay(for: referenceDate)
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) else { return 0 }
        return logs.filter { log in
            guard log.completed else { return false }
            let day = calendar.startOfDay(for: log.date)
            return day >= start && day <= end
        }.count
    }

    func streak(referenceDate: Date = .now, calendar: Calendar = .current) -> Int {
        var day = calendar.startOfDay(for: referenceDate)
        var count = 0

        while isCompleted(on: day, calendar: calendar) {
            count += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }
            day = previousDay
        }

        return count
    }

    func toggleCompletion(on date: Date = .now, calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: date)

        if let existing = logs.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            existing.completed.toggle()
        } else {
            let newLog = HabitLog(date: day, completed: true, habit: self)
            logs.append(newLog)
        }
    }

    static func weekInterval(containing date: Date, weekStart: Int, calendar: Calendar = .current) -> DateInterval? {
        guard (1...7).contains(weekStart) else { return nil }
        let normalizedDate = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: normalizedDate)
        let daysFromStart = (weekday - weekStart + 7) % 7
        guard let start = calendar.date(byAdding: .day, value: -daysFromStart, to: normalizedDate),
              let end = calendar.date(byAdding: .day, value: 7, to: start) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }

    private static func encodeWeekdays(_ weekdays: Set<Int>) -> String {
        weekdays
            .filter { (1...7).contains($0) }
            .sorted()
            .map(String.init)
            .joined(separator: ",")
    }

    private static func decodeWeekdays(_ raw: String) -> Set<Int> {
        let values = raw
            .split(separator: ",")
            .compactMap { Int($0) }
            .filter { (1...7).contains($0) }
        return Set(values)
    }
}

@Model
final class HabitLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var completed: Bool

    var habit: Habit?

    init(id: UUID = UUID(), date: Date, completed: Bool, habit: Habit? = nil) {
        self.id = id
        self.date = date
        self.completed = completed
        self.habit = habit
    }
}

enum HabitColor: String, CaseIterable, Codable, Identifiable {
    case blue
    case green
    case orange
    case red
    case pink

    var id: String { rawValue }
}
