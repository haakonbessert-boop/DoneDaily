import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Habits",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Lege deinen ersten Habit im Habits-Tab an.")
                    )
                } else {
                    List {
                        Section("Heute") {
                            ForEach(habits) { habit in
                                HStack(spacing: 12) {
                                    Image(systemName: habit.iconName)
                                        .foregroundStyle(habit.color.swiftUIColor)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(habit.name)
                                            .font(.headline)
                                        Text("Streak: \(habit.streak()) Tage")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Text("Diese Woche: \(habit.completedThisWeek(weekStart: settings.weekStart.rawValue))/\(habit.targetPerWeek)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        habit.toggleCompletion()
                                        modelContext.saveIfNeeded()
                                    } label: {
                                        Image(systemName: habit.isCompleted(on: .now) ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(habit.isCompleted(on: .now) ? habit.color.swiftUIColor : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("DoneDaily")
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(AppSettings())
        .modelContainer(PreviewData.container)
}
