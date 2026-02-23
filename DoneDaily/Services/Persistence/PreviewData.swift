import SwiftData

@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let schema = Schema([
            HabitGroup.self,
            Habit.self,
            HabitLog.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])

        let mindGroup = HabitGroup(name: "Mind")
        let healthGroup = HabitGroup(name: "Health")
        container.mainContext.insert(mindGroup)
        container.mainContext.insert(healthGroup)

        let habits = [
            Habit(name: "10 Minuten Lesen", iconName: "book.fill", color: .blue, targetPerWeek: 5, group: mindGroup),
            Habit(name: "Workout", iconName: "figure.run", color: .green, targetPerWeek: 4, group: healthGroup),
            Habit(name: "Kein Zucker", iconName: "leaf.fill", color: .orange, targetPerWeek: 7)
        ]

        for habit in habits {
            container.mainContext.insert(habit)
        }

        container.mainContext.saveIfNeeded()
        return container
    }()
}
