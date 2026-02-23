import Foundation
import UserNotifications
import XCTest
@testable import DoneDaily

private final class MockNotificationCenter: NotificationCenterScheduling {
    private var addedRequestsStorage: [UNNotificationRequest] = []
    private var removedIdentifiersStorage: [String] = []
    private let queue = DispatchQueue(label: "MockNotificationCenter.queue")

    var addedRequests: [UNNotificationRequest] {
        queue.sync { addedRequestsStorage }
    }

    var removedIdentifiers: [String] {
        queue.sync { removedIdentifiersStorage }
    }

    func add(_ request: UNNotificationRequest) async throws {
        queue.sync { addedRequestsStorage.append(request) }
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        queue.sync { removedIdentifiersStorage = identifiers }
    }
}

final class HabitReminderSchedulerTests: XCTestCase {
    func testBuildRequestsCreatesOnePerWeekday() {
        let habit = Habit(
            name: "Meditation",
            iconName: "brain.head.profile",
            color: .blue,
            targetPerWeek: 5,
            reminderEnabled: true,
            reminderHour: 21,
            reminderMinute: 15,
            reminderWeekdays: [2, 4, 6]
        )

        let requests = HabitReminderScheduler.buildRequests(for: habit)
        XCTAssertEqual(requests.count, 3)
        XCTAssertTrue(requests.allSatisfy { $0.identifier.contains(habit.id.uuidString) })
    }

    func testScheduleIfEnabledCancelsExistingThenAddsRequests() async {
        let center = MockNotificationCenter()
        let habit = Habit(
            name: "Workout",
            iconName: "figure.run",
            color: .green,
            targetPerWeek: 4,
            reminderEnabled: true,
            reminderWeekdays: [1, 3, 5]
        )

        await HabitReminderScheduler.scheduleIfEnabled(for: habit, center: center)

        XCTAssertEqual(center.removedIdentifiers.count, 7)
        XCTAssertEqual(center.addedRequests.count, 3)
    }

    func testScheduleDoesNotAddForArchivedHabit() async {
        let center = MockNotificationCenter()
        let habit = Habit(
            name: "Lesen",
            iconName: "book.fill",
            color: .orange,
            targetPerWeek: 7,
            isArchived: true,
            reminderEnabled: true,
            reminderWeekdays: [2, 3]
        )

        await HabitReminderScheduler.scheduleIfEnabled(for: habit, center: center)

        XCTAssertEqual(center.removedIdentifiers.count, 7)
        XCTAssertEqual(center.addedRequests.count, 0)
    }

    func testWeekdaysPatternBuildsFiveRequests() {
        let habit = Habit(
            name: "Planung",
            iconName: "checklist",
            color: .blue,
            targetPerWeek: 5,
            reminderEnabled: true,
            reminderPattern: .weekdays,
            reminderWeekdays: [2, 3, 4, 5, 6]
        )

        let requests = HabitReminderScheduler.buildRequests(for: habit)
        XCTAssertEqual(requests.count, 5)
    }
}
