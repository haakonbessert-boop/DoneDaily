import SwiftData
import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    private var calculator: HabitStatsCalculator {
        HabitStatsCalculator(habits: habits, weekStart: settings.weekStart)
    }

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Statistik",
                        systemImage: "chart.bar",
                        description: Text("Füge Habits hinzu und hake sie täglich ab.")
                    )
                } else {
                    List {
                        Section("Diese Woche") {
                            statRow(title: "Erledigt", value: "\(calculator.totalCompletedThisWeek)")
                            statRow(title: "Ziel", value: "\(calculator.totalTargetsThisWeek)")
                            statRow(
                                title: "Completion Rate",
                                value: calculator.completionRateThisWeek.formatted(.percent.precision(.fractionLength(0)))
                            )
                        }

                        Section("Verlauf") {
                            statRow(title: "Letzte 7 Tage", value: "\(calculator.totalCompleted(days: 7))")
                            statRow(title: "Letzte 30 Tage", value: "\(calculator.totalCompleted(days: 30))")
                            statRow(
                                title: "Trend (7 vs 30)",
                                value: calculator.trendPercent(deltaFromShortWindow: 7, longWindow: 30).formatted(.percent.precision(.fractionLength(0)))
                            )
                        }

                        Section("Pro Habit (30 Tage)") {
                            ForEach(habits) { habit in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(habit.name)
                                        Spacer()
                                        Text(calculator.habitCompletionRate(habit: habit, days: 30).formatted(.percent.precision(.fractionLength(0))))
                                            .foregroundStyle(.secondary)
                                    }
                                    ProgressView(value: calculator.habitCompletionRate(habit: habit, days: 30))
                                        .tint(habit.color.swiftUIColor)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Statistik")
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(AppSettings())
        .modelContainer(PreviewData.container)
}
