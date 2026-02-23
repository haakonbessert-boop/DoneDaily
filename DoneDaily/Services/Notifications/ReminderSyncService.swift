import SwiftData

enum ReminderSyncService {
    static func syncAll(
        context: ModelContext,
        scheduler: @escaping (Habit) async -> Void = { habit in
            await HabitReminderScheduler.scheduleIfEnabled(for: habit)
        }
    ) {
        Task {
            await syncAllNow(context: context, scheduler: scheduler)
        }
    }

    static func syncAllNow(
        context: ModelContext,
        scheduler: @escaping (Habit) async -> Void = { habit in
            await HabitReminderScheduler.scheduleIfEnabled(for: habit)
        }
    ) async {
        do {
            let habits = try context.fetch(FetchDescriptor<Habit>())
            for habit in habits {
                await scheduler(habit)
            }
        } catch {
            AppErrorReporter.report("Failed to sync reminders: \(error)")
        }
    }
}
