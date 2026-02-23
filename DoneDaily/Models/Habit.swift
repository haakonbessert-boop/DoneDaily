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

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        color: HabitColor,
        targetPerWeek: Int,
        createdAt: Date = .now,
        logs: [HabitLog] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorRawValue = color.rawValue
        self.targetPerWeek = max(1, targetPerWeek)
        self.createdAt = createdAt
        self.logs = logs
    }

    var color: HabitColor {
        get { HabitColor(rawValue: colorRawValue) ?? .blue }
        set { colorRawValue = newValue.rawValue }
    }

    func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        logs.contains { log in
            calendar.isDate(log.date, inSameDayAs: date) && log.completed
        }
    }

    var completedThisWeek: Int {
        let calendar = Calendar.current
        guard let week = calendar.dateInterval(of: .weekOfYear, for: .now) else {
            return 0
        }

        return logs.filter { log in
            log.completed && week.contains(log.date)
        }.count
    }

    var streak: Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: .now)
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
