import SwiftData
import SwiftUI

@main
struct DoneDailyApp: App {
    @StateObject private var appSettings = AppSettings()
    private let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Habit.self,
                HabitLog.self
            ])
            let configuration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: [configuration])
            seedIfNeeded(context: container.mainContext)
            syncReminderSchedules(context: container.mainContext)
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
        }
        .modelContainer(container)
    }

    private func seedIfNeeded(context: ModelContext) {
        var descriptor = FetchDescriptor<Habit>()
        descriptor.fetchLimit = 1

        do {
            let existing = try context.fetch(descriptor)
            guard existing.isEmpty else { return }

            let habits = [
                Habit(name: "10 Minuten Lesen", iconName: "book.fill", color: .blue, targetPerWeek: 5),
                Habit(name: "Workout", iconName: "figure.run", color: .green, targetPerWeek: 4),
                Habit(name: "Kein Zucker", iconName: "leaf.fill", color: .orange, targetPerWeek: 7)
            ]

            for habit in habits {
                context.insert(habit)
            }

            context.saveIfNeeded()
        } catch {
            assertionFailure("Failed to seed initial habits: \(error)")
        }
    }

    private func syncReminderSchedules(context: ModelContext) {
        do {
            let habits = try context.fetch(FetchDescriptor<Habit>())
            Task {
                for habit in habits {
                    await HabitReminderScheduler.scheduleIfEnabled(for: habit)
                }
            }
        } catch {
            assertionFailure("Failed to sync reminders: \(error)")
        }
    }
}
