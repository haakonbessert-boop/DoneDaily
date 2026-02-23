import SwiftData
import SwiftUI

struct StatsView: View {
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    private var totalCompletedThisWeek: Int {
        habits.map(\.completedThisWeek).reduce(0, +)
    }

    private var totalTargetsThisWeek: Int {
        habits.map(\.targetPerWeek).reduce(0, +)
    }

    private var completionRateThisWeek: Double {
        guard totalTargetsThisWeek > 0 else { return 0 }
        return min(1.0, Double(totalCompletedThisWeek) / Double(totalTargetsThisWeek))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Diese Woche") {
                    statRow(title: "Erledigt", value: "\(totalCompletedThisWeek)")
                    statRow(title: "Ziel", value: "\(totalTargetsThisWeek)")
                    statRow(
                        title: "Completion Rate",
                        value: completionRateThisWeek.formatted(.percent.precision(.fractionLength(0)))
                    )
                }

                Section("Streaks") {
                    ForEach(habits) { habit in
                        statRow(title: habit.name, value: "\(habit.streak) Tage")
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
        .modelContainer(PreviewData.container)
}
