import XCTest
@testable import DoneDaily

final class HabitAnalyticsTests: XCTestCase {
    func testCompletedThisWeekWithMondayStart() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let monday = makeDate(2026, 2, 23, calendar: calendar)
        let sundayBefore = makeDate(2026, 2, 22, calendar: calendar)

        let habit = Habit(name: "Test", iconName: "book.fill", color: .blue, targetPerWeek: 7)
        habit.logs = [
            HabitLog(date: monday, completed: true, habit: habit),
            HabitLog(date: sundayBefore, completed: true, habit: habit)
        ]

        let count = habit.completedThisWeek(referenceDate: monday, weekStart: WeekStart.monday.rawValue, calendar: calendar)
        XCTAssertEqual(count, 1)
    }

    func testCompletedCountInLastSevenDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let reference = makeDate(2026, 2, 23, calendar: calendar)
        let inRange = makeDate(2026, 2, 20, calendar: calendar)
        let outOfRange = makeDate(2026, 2, 10, calendar: calendar)

        let habit = Habit(name: "Test", iconName: "book.fill", color: .blue, targetPerWeek: 7)
        habit.logs = [
            HabitLog(date: inRange, completed: true, habit: habit),
            HabitLog(date: outOfRange, completed: true, habit: habit)
        ]

        let count = habit.completedCount(inLast: 7, referenceDate: reference, calendar: calendar)
        XCTAssertEqual(count, 1)
    }

    func testStreakCountsConsecutiveDaysOnly() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let today = makeDate(2026, 2, 23, calendar: calendar)
        let yesterday = makeDate(2026, 2, 22, calendar: calendar)
        let threeDaysAgo = makeDate(2026, 2, 20, calendar: calendar)

        let habit = Habit(name: "Test", iconName: "book.fill", color: .blue, targetPerWeek: 7)
        habit.logs = [
            HabitLog(date: today, completed: true, habit: habit),
            HabitLog(date: yesterday, completed: true, habit: habit),
            HabitLog(date: threeDaysAgo, completed: true, habit: habit)
        ]

        XCTAssertEqual(habit.streak(referenceDate: today, calendar: calendar), 2)
    }

    func testToggleCompletionSameDayDoesNotCreateDuplicateLog() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let date = makeDate(2026, 2, 23, calendar: calendar)
        let habit = Habit(name: "Test", iconName: "book.fill", color: .blue, targetPerWeek: 7)

        habit.toggleCompletion(on: date, calendar: calendar)
        habit.toggleCompletion(on: date, calendar: calendar)

        XCTAssertEqual(habit.logs.count, 1)
        XCTAssertEqual(habit.logs.first?.completed, false)
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) -> Date {
        let components = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: year, month: month, day: day)
        return components.date!
    }
}
