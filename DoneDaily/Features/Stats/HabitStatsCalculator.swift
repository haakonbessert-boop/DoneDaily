import Foundation

struct CompletionRatePoint: Identifiable {
    let date: Date
    let rate: Double

    var id: Date { date }
}

struct WeekdayBarPoint: Identifiable {
    let weekday: Int
    let value: Double

    var id: Int { weekday }
}

struct HeatmapCell: Identifiable {
    let date: Date
    let intensity: Double

    var id: Date { date }
}

struct HabitDeviation: Identifiable {
    let habit: Habit
    let completionRate: Double
    let deltaToTarget: Double

    var id: UUID { habit.id }
}

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

    func habitCompletionRate(habit: Habit, days: Int) -> Double {
        guard days > 0 else { return 0 }
        let reference = calendar.startOfDay(for: .now)
        let total = (0..<days).reduce(0.0) { partial, offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: reference) else { return partial }
            return partial + habit.progressRatio(on: day, calendar: calendar)
        }
        return min(1.0, total / Double(days))
    }

    func completionRateSeries(days: Int) -> [CompletionRatePoint] {
        AppPerformanceMonitor.measure("completionRateSeries_\(days)d") {
            guard days > 0, !habits.isEmpty else { return [] }
            let reference = calendar.startOfDay(for: .now)

            return (0..<days).reversed().compactMap { offset -> CompletionRatePoint? in
                guard let day = calendar.date(byAdding: .day, value: -offset, to: reference) else { return nil }
                let completed = habits.reduce(0.0) { partial, habit in
                    partial + habit.progressRatio(on: day, calendar: calendar)
                }
                let rate = completed / Double(max(1, habits.count))
                return CompletionRatePoint(date: day, rate: rate)
            }
        }
    }

    func completionRate(days: Int, endingAt referenceDate: Date = .now) -> Double {
        guard days > 0, !habits.isEmpty else { return 0 }
        let reference = calendar.startOfDay(for: referenceDate)

        let completed = (0..<days).reduce(0.0) { partial, offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: reference) else { return partial }
            let count = habits.reduce(0.0) { sum, habit in
                sum + habit.progressRatio(on: day, calendar: calendar)
            }
            return partial + count
        }

        let total = Double(days * habits.count)
        return total > 0 ? completed / total : 0
    }

    func completionComparison(days: Int) -> (current: Double, previous: Double) {
        let current = completionRate(days: days)
        guard let previousReference = calendar.date(byAdding: .day, value: -days, to: .now) else {
            return (current, 0)
        }
        let previous = completionRate(days: days, endingAt: previousReference)
        return (current, previous)
    }

    func habitDeviations(days: Int) -> [HabitDeviation] {
        guard days > 0 else { return [] }
        return habits
            .map { habit in
                let rate = habitCompletionRate(habit: habit, days: days)
                let expected = min(1.0, Double(habit.targetPerWeek) / 7.0)
                let delta = rate - expected
                return HabitDeviation(habit: habit, completionRate: rate, deltaToTarget: delta)
            }
            .sorted { $0.deltaToTarget > $1.deltaToTarget }
    }

    func weekdayBars(days: Int) -> [WeekdayBarPoint] {
        guard days > 0, !habits.isEmpty else {
            return (1...7).map { WeekdayBarPoint(weekday: $0, value: 0) }
        }

        let reference = calendar.startOfDay(for: .now)
        var scores: [Int: Double] = [:]
        var totals: [Int: Double] = [:]

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: reference) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            totals[weekday, default: 0] += Double(habits.count)
            let dayScore = habits.reduce(0.0) { partial, habit in
                partial + habit.progressRatio(on: day, calendar: calendar)
            }
            scores[weekday, default: 0] += dayScore
        }

        return (1...7).map { weekday in
            let total = totals[weekday, default: 0]
            let value = total > 0 ? scores[weekday, default: 0] / total : 0
            return WeekdayBarPoint(weekday: weekday, value: value)
        }
    }

    func monthlyHeatmap(weeks: Int = 12) -> [HeatmapCell] {
        let days = max(7, weeks * 7)
        return completionRateSeries(days: days).map { HeatmapCell(date: $0.date, intensity: $0.rate) }
    }
}
