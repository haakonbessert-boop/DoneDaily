import SwiftData
import SwiftUI

struct StatsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var period: InsightPeriod = .days30
    @State private var selectedHabit: Habit?

    private var activeHabits: [Habit] {
        habits.filter(\.isActive)
    }

    private var calculator: HabitStatsCalculator {
        HabitStatsCalculator(habits: activeHabits, weekStart: settings.weekStart)
    }

    private var trendSeries: [CompletionRatePoint] {
        calculator.completionRateSeries(days: period.rawValue)
    }

    private var weekdayBars: [WeekdayBarPoint] {
        calculator.weekdayBars(days: period.rawValue)
    }

    private var heatmapCells: [HeatmapCell] {
        calculator.monthlyHeatmap(weeks: 12)
    }

    private var comparison: (current: Double, previous: Double) {
        calculator.completionComparison(days: period.rawValue)
    }

    private var deviations: [HabitDeviation] {
        calculator.habitDeviations(days: period.rawValue)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppDesign.stackSpacing) {
                    InsightsPeriodControl(period: $period)

                    if activeHabits.isEmpty {
                        AppCard {
                            Text("Füge aktive Habits hinzu und hake sie täglich ab.")
                                .foregroundStyle(secondaryText)
                        }
                    } else {
                        InsightsTrendCard(
                            series: trendSeries,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            accent: accent
                        )
                        InsightsWeekdayCard(
                            bars: weekdayBars,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            accent: accent,
                            weekdayLabel: weekdayLabel
                        )
                        InsightsHeatmapCard(
                            cells: heatmapCells,
                            primaryText: primaryText,
                            accent: accent
                        )
                        InsightsDrilldownCard(
                            rows: Array(deviations.prefix(5)),
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            onSelect: { habit in
                                selectedHabit = habit
                            }
                        )
                        InsightsComparisonCard(
                            current: comparison.current,
                            previous: comparison.previous,
                            primaryText: primaryText
                        )
                    }
                }
                .padding(.horizontal, AppDesign.screenPadding)
                .padding(.bottom, 32)
            }
            .background(AppBackgroundView())
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .tint(accent)
            .sheet(item: $selectedHabit) { habit in
                NavigationStack {
                    habitDrilldown(habit)
                        .navigationTitle(habit.name)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    private func habitDrilldown(_ habit: Habit) -> some View {
        let shortRate = calculator.habitCompletionRate(habit: habit, days: 7)
        let longRate = calculator.habitCompletionRate(habit: habit, days: 30)
        let streak = habit.streak()

        return List {
            Section("Leistung") {
                Label("7 Tage: \(Int((shortRate * 100).rounded()))%", systemImage: "calendar")
                Label("30 Tage: \(Int((longRate * 100).rounded()))%", systemImage: "calendar.badge.clock")
                Label("Aktuelle Streak: \(streak)", systemImage: "flame")
            }

            Section("Ziel") {
                Label("\(habit.targetPerWeek)x pro Woche", systemImage: "target")
                Label(habit.category.title, systemImage: "tag")
            }
        }
    }

    private func weekdayLabel(_ weekday: Int) -> String {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        return symbols[max(0, min(symbols.count - 1, weekday - 1))]
    }

    private var primaryText: Color {
        colorScheme == .dark ? .appPrimaryTextDark : .appPrimaryTextLight
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .appSecondaryTextDark : .appSecondaryTextLight
    }

    private var accent: Color {
        colorScheme == .dark ? .appAccentDark : .appAccentLight
    }
}

enum InsightPeriod: Int, CaseIterable, Identifiable {
    case days7 = 7
    case days30 = 30
    case days90 = 90

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .days7:
            return "Woche"
        case .days30:
            return "Monat"
        case .days90:
            return "3 Monate"
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(AppSettings())
        .modelContainer(PreviewData.container)
}
