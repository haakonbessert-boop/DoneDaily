import SwiftData
import XCTest
@testable import DoneDaily

final class ReminderSyncServiceTests: XCTestCase {
    @MainActor
    func testSyncAllSchedulesEveryHabit() async throws {
        let schema = Schema([HabitGroup.self, Habit.self, HabitLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        context.insert(Habit(name: "A", iconName: "a.circle", color: .blue, targetPerWeek: 3))
        context.insert(Habit(name: "B", iconName: "b.circle", color: .green, targetPerWeek: 4))
        _ = context.saveIfNeeded()

        var scheduled: [String] = []
        await ReminderSyncService.syncAllNow(context: context) { habit in
            scheduled.append(habit.name)
        }

        XCTAssertEqual(Set(scheduled), Set(["A", "B"]))
    }
}
