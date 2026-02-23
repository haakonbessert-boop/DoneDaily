import Foundation
import SwiftData

@Model
final class HabitGroup {
    @Attribute(.unique) var id: UUID
    var name: String = ""
    var sortOrder: Int = 0
    var createdAt: Date = Foundation.Date.now

    @Relationship(deleteRule: .nullify, inverse: \Habit.group)
    var habits: [Habit] = []

    init(id: UUID = UUID(), name: String, sortOrder: Int = 0, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String = ""
    var iconName: String = "checkmark.seal.fill"
    var colorRawValue: String = "blue"
    var targetPerWeek: Int = 1
    var trackingTypeRaw: String = "binary"
    var dailyTarget: Int = 1
    var categoryRawValue: String = "health"
    var notes: String = ""
    var isArchived: Bool = false
    var isPaused: Bool = false
    var pausedUntil: Date?
    var createdAt: Date = Foundation.Date.now
    var reminderEnabled: Bool = false
    var reminderHour: Int = 20
    var reminderMinute: Int = 0
    var reminderPatternRaw: String = "daily"
    var reminderMissedDaysThreshold: Int = 2
    var reminderWeekdaysRaw: String = "1,2,3,4,5,6,7"
    var sortOrder: Int = 0
    var group: HabitGroup?

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog] = []

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        color: HabitColor,
        targetPerWeek: Int,
        trackingType: HabitTrackingType = .binary,
        dailyTarget: Int = 1,
        category: HabitCategory = .health,
        notes: String = "",
        isArchived: Bool = false,
        isPaused: Bool = false,
        pausedUntil: Date? = nil,
        reminderEnabled: Bool = false,
        reminderHour: Int = 20,
        reminderMinute: Int = 0,
        reminderPattern: ReminderPattern = .daily,
        reminderMissedDaysThreshold: Int = 2,
        reminderWeekdays: Set<Int> = Set(1...7),
        sortOrder: Int = 0,
        group: HabitGroup? = nil,
        createdAt: Date = .now,
        logs: [HabitLog] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorRawValue = color.rawValue
        self.targetPerWeek = max(1, targetPerWeek)
        self.trackingTypeRaw = trackingType.rawValue
        self.dailyTarget = max(1, dailyTarget)
        self.categoryRawValue = category.rawValue
        self.notes = notes
        self.isArchived = isArchived
        self.isPaused = isPaused
        self.pausedUntil = pausedUntil
        self.createdAt = createdAt
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.reminderPatternRaw = reminderPattern.rawValue
        self.reminderMissedDaysThreshold = max(1, reminderMissedDaysThreshold)
        self.reminderWeekdaysRaw = Habit.encodeWeekdays(reminderWeekdays)
        self.sortOrder = max(0, sortOrder)
        self.group = group
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

    var reminderPattern: ReminderPattern {
        get { ReminderPattern(rawValue: reminderPatternRaw) ?? .daily }
        set { reminderPatternRaw = newValue.rawValue }
    }

    var category: HabitCategory {
        get { HabitCategory(rawValue: categoryRawValue) ?? .health }
        set { categoryRawValue = newValue.rawValue }
    }

    var trackingType: HabitTrackingType {
        get { HabitTrackingType(rawValue: trackingTypeRaw) ?? .binary }
        set { trackingTypeRaw = newValue.rawValue }
    }

    var isActive: Bool {
        !isArchived && !isPauseActive(on: .now)
    }

    func isPauseActive(on date: Date, calendar: Calendar = .current) -> Bool {
        guard isPaused else { return false }
        guard let pausedUntil else { return true }
        return calendar.startOfDay(for: pausedUntil) >= calendar.startOfDay(for: date)
    }

    func isDue(on date: Date, calendar: Calendar = .current) -> Bool {
        guard isActive else { return false }
        guard reminderEnabled else { return true }
        let weekday = calendar.component(.weekday, from: date)
        return reminderWeekdays.contains(weekday)
    }

    func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        dailyProgress(on: date, calendar: calendar) >= max(1, trackingType == .binary ? 1 : dailyTarget)
    }

    func completedThisWeek(referenceDate: Date = .now, weekStart: Int = 2, calendar: Calendar = .current) -> Int {
        guard let week = Self.weekInterval(containing: referenceDate, weekStart: weekStart, calendar: calendar) else {
            return 0
        }

        let start = calendar.startOfDay(for: week.start)
        return (0..<7).reduce(0) { partial, offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return partial }
            return partial + (isCompleted(on: day, calendar: calendar) ? 1 : 0)
        }
    }

    func completedCount(inLast days: Int, referenceDate: Date = .now, calendar: Calendar = .current) -> Int {
        guard days > 0 else { return 0 }
        let end = calendar.startOfDay(for: referenceDate)
        guard calendar.date(byAdding: .day, value: -(days - 1), to: end) != nil else { return 0 }
        return (0..<days).reduce(0) { partial, offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: end) else { return partial }
            return partial + (isCompleted(on: day, calendar: calendar) ? 1 : 0)
        }
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
        if trackingType == .count {
            if isCompleted(on: day, calendar: calendar) {
                setProgress(0, on: day, calendar: calendar)
            } else {
                setProgress(dailyTarget, on: day, calendar: calendar)
            }
            return
        }

        if let existing = logs.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            existing.completed.toggle()
            existing.progressCount = existing.completed ? 1 : 0
        } else {
            let newLog = HabitLog(date: day, completed: true, progressCount: 1, habit: self)
            logs.append(newLog)
        }
    }

    func dailyProgress(on date: Date = .now, calendar: Calendar = .current) -> Int {
        let day = calendar.startOfDay(for: date)
        guard let existing = logs.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) else { return 0 }
        if trackingType == .binary {
            return existing.completed ? 1 : 0
        }
        return max(existing.progressCount, existing.completed ? dailyTarget : 0)
    }

    func progressRatio(on date: Date = .now, calendar: Calendar = .current) -> Double {
        let goal = max(1, trackingType == .binary ? 1 : dailyTarget)
        return min(1, Double(dailyProgress(on: date, calendar: calendar)) / Double(goal))
    }

    func incrementProgress(on date: Date = .now, calendar: Calendar = .current) {
        let goal = max(1, trackingType == .binary ? 1 : dailyTarget)
        let next = min(goal, dailyProgress(on: date, calendar: calendar) + 1)
        setProgress(next, on: date, calendar: calendar)
    }

    func decrementProgress(on date: Date = .now, calendar: Calendar = .current) {
        let next = max(0, dailyProgress(on: date, calendar: calendar) - 1)
        setProgress(next, on: date, calendar: calendar)
    }

    func setProgress(_ progress: Int, on date: Date = .now, calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: date)
        let goal = max(1, trackingType == .binary ? 1 : dailyTarget)
        let clamped = max(0, min(goal, progress))
        let completed = clamped >= goal

        if let existing = logs.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            existing.progressCount = clamped
            existing.completed = completed
        } else {
            logs.append(HabitLog(date: day, completed: completed, progressCount: clamped, habit: self))
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
    var progressCount: Int

    var habit: Habit?

    init(id: UUID = UUID(), date: Date, completed: Bool, progressCount: Int = 0, habit: Habit? = nil) {
        self.id = id
        self.date = date
        self.completed = completed
        self.progressCount = max(0, progressCount)
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

enum HabitCategory: String, CaseIterable, Codable, Identifiable {
    case health
    case fitness
    case learning
    case mindfulness
    case productivity
    case social
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health:
            return "Gesundheit"
        case .fitness:
            return "Fitness"
        case .learning:
            return "Lernen"
        case .mindfulness:
            return "Achtsamkeit"
        case .productivity:
            return "Produktiv"
        case .social:
            return "Soziales"
        case .other:
            return "Sonstiges"
        }
    }
}

enum ReminderPattern: String, CaseIterable, Codable, Identifiable {
    case daily
    case weekdays
    case gentleEvening
    case afterMissedDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            return "Täglich"
        case .weekdays:
            return "Werktage"
        case .gentleEvening:
            return "Sanfter Abend"
        case .afterMissedDays:
            return "Nach Fehl-Tagen"
        }
    }
}

enum HabitTrackingType: String, CaseIterable, Codable, Identifiable {
    case binary
    case count

    var id: String { rawValue }

    var title: String {
        switch self {
        case .binary:
            return "Einmal pro Tag"
        case .count:
            return "Mehrmals pro Tag"
        }
    }
}
