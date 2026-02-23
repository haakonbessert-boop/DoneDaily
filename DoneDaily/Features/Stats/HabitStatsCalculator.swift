import Foundation

struct HabitStatsCalculator {
    let habits: [Habit]
    let weekStart: WeekStart
    let calendar: Calendar

    init(habits: [Habit], weekStart: WeekStart, calendar: Calendar = .current) {
        self.habits = habits
        self.weekStart = weekStart
        self.calendar = calendar
    }

    var totalCompletedThisWeek: Int {
        habits.map { $0.completedThisWeek(weekStart: weekStart.rawValue, calendar: calendar) }.reduce(0, +)
    }

    var totalTargetsThisWeek: Int {
        habits.map(\.targetPerWeek).reduce(0, +)
    }

    var completionRateThisWeek: Double {
        guard totalTargetsThisWeek > 0 else { return 0 }
        return min(1.0, Double(totalCompletedThisWeek) / Double(totalTargetsThisWeek))
    }

    func totalCompleted(days: Int) -> Int {
        habits.map { $0.completedCount(inLast: days, calendar: calendar) }.reduce(0, +)
    }

    func trendPercent(deltaFromShortWindow shortDays: Int, longWindow longDays: Int) -> Double {
        let shortRate = averageDailyCompletion(days: shortDays)
        let longRate = averageDailyCompletion(days: longDays)
        guard longRate > 0 else { return 0 }
        return (shortRate - longRate) / longRate
    }

    func habitCompletionRate(habit: Habit, days: Int) -> Double {
        guard days > 0 else { return 0 }
        let completed = habit.completedCount(inLast: days, calendar: calendar)
        let expected = Double(habit.targetPerWeek) / 7.0 * Double(days)
        guard expected > 0 else { return 0 }
        return min(1.0, Double(completed) / expected)
    }

    private func averageDailyCompletion(days: Int) -> Double {
        guard days > 0 else { return 0 }
        return Double(totalCompleted(days: days)) / Double(days)
    }
}
