import Foundation
import SwiftData

struct HabitExportRecord: Codable {
    let id: String
    let name: String
    let iconName: String?
    let color: String?
    let category: String
    let categoryRawValue: String?
    let notes: String?
    let groupName: String?
    let targetPerWeek: Int
    let trackingType: String?
    let dailyTarget: Int?
    let sortOrder: Int?
    let streak: Int
    let archived: Bool
    let paused: Bool
    let reminderEnabled: Bool
    let reminderPattern: String?
    let reminderMissedDaysThreshold: Int?
    let reminderHour: Int?
    let reminderMinute: Int?
    let reminderWeekdays: [Int]?
}

enum DataExportService {
    static func exportFiles(context: ModelContext) throws -> (csv: URL, json: URL) {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
        let habits = try context.fetch(descriptor)
        let records = habits.map { makeRecord($0) }

        let base = fileBaseName()
        let directory = FileManager.default.temporaryDirectory
        let csvURL = directory.appendingPathComponent("\(base).csv")
        let jsonURL = directory.appendingPathComponent("\(base).json")

        try makeCSV(records).write(to: csvURL, atomically: true, encoding: .utf8)
        try JSONEncoder.pretty.write(records, to: jsonURL)
        return (csvURL, jsonURL)
    }

    static func makeRecord(_ habit: Habit) -> HabitExportRecord {
        HabitExportRecord(
            id: habit.id.uuidString,
            name: habit.name,
            iconName: habit.iconName,
            color: habit.color.rawValue,
            category: habit.category.title,
            categoryRawValue: habit.category.rawValue,
            notes: habit.notes.isEmpty ? nil : habit.notes,
            groupName: habit.group?.name,
            targetPerWeek: habit.targetPerWeek,
            trackingType: habit.trackingType.rawValue,
            dailyTarget: habit.dailyTarget,
            sortOrder: habit.sortOrder,
            streak: habit.streak(),
            archived: habit.isArchived,
            paused: habit.isPaused,
            reminderEnabled: habit.reminderEnabled,
            reminderPattern: habit.reminderPattern.rawValue,
            reminderMissedDaysThreshold: habit.reminderMissedDaysThreshold,
            reminderHour: habit.reminderHour,
            reminderMinute: habit.reminderMinute,
            reminderWeekdays: habit.reminderWeekdays.sorted()
        )
    }

    static func makeCSV(_ records: [HabitExportRecord]) -> String {
        let header = "id,name,group,category,target_per_week,daily_target,tracking,streak,archived,paused,reminder_enabled,color,pattern"
        let rows = records.map { record in
            [
                record.id,
                csvEscaped(record.name),
                csvEscaped(record.groupName ?? ""),
                csvEscaped(record.category),
                "\(record.targetPerWeek)",
                "\(record.dailyTarget ?? 1)",
                csvEscaped(record.trackingType ?? HabitTrackingType.binary.rawValue),
                "\(record.streak)",
                record.archived ? "1" : "0",
                record.paused ? "1" : "0",
                record.reminderEnabled ? "1" : "0",
                csvEscaped(record.color ?? ""),
                csvEscaped(record.reminderPattern ?? "")
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    @discardableResult
    static func importHabits(from jsonURL: URL, context: ModelContext) throws -> Int {
        let data = try Data(contentsOf: jsonURL)
        let records = try JSONDecoder().decode([HabitExportRecord].self, from: data)
        guard !records.isEmpty else { return 0 }

        let existingGroups = try context.fetch(FetchDescriptor<HabitGroup>(sortBy: [SortDescriptor(\HabitGroup.sortOrder)]))
        var groupsByName = Dictionary(uniqueKeysWithValues: existingGroups.map { ($0.name.lowercased(), $0) })
        var imported = 0

        for record in records {
            let trimmedName = record.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { continue }

            let group: HabitGroup? = {
                guard let groupName = record.groupName?.trimmingCharacters(in: .whitespacesAndNewlines), !groupName.isEmpty else { return nil }
                let key = groupName.lowercased()
                if let existing = groupsByName[key] {
                    return existing
                }
                let created = HabitGroup(name: groupName, sortOrder: groupsByName.count)
                context.insert(created)
                groupsByName[key] = created
                return created
            }()

            let habit = Habit(
                name: trimmedName,
                iconName: record.iconName ?? "checkmark.seal.fill",
                color: HabitColor(rawValue: record.color ?? "") ?? .blue,
                targetPerWeek: max(1, record.targetPerWeek),
                trackingType: HabitTrackingType(rawValue: record.trackingType ?? "") ?? .binary,
                dailyTarget: max(1, record.dailyTarget ?? 1),
                category: HabitCategory(rawValue: record.categoryRawValue ?? "") ?? .other,
                notes: record.notes ?? "",
                isArchived: record.archived,
                isPaused: record.paused,
                reminderEnabled: record.reminderEnabled,
                reminderHour: record.reminderHour ?? 20,
                reminderMinute: record.reminderMinute ?? 0,
                reminderPattern: ReminderPattern(rawValue: record.reminderPattern ?? "") ?? .daily,
                reminderMissedDaysThreshold: max(1, record.reminderMissedDaysThreshold ?? 2),
                reminderWeekdays: Set(record.reminderWeekdays ?? Array(1...7)),
                sortOrder: max(0, record.sortOrder ?? imported),
                group: group
            )
            context.insert(habit)
            imported += 1
        }

        _ = context.saveIfNeeded()
        return imported
    }

    private static func fileBaseName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return "donedaily-export-\(formatter.string(from: .now))"
    }

    private static func csvEscaped(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    func write<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try encode(value)
        try data.write(to: url, options: [.atomic])
    }
}
