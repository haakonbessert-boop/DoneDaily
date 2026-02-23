import SwiftData
import SwiftUI

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var isAddingHabit = false

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "Keine Habits vorhanden",
                        systemImage: "plus.circle",
                        description: Text("Erstelle einen Habit, um loszulegen.")
                    )
                } else {
                    List {
                        ForEach(habits) { habit in
                            NavigationLink {
                                EditHabitView(habit: habit)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label(habit.name, systemImage: habit.iconName)
                                        .foregroundStyle(habit.color.swiftUIColor)
                                        .font(.headline)
                                    Text("Ziel: \(habit.targetPerWeek)x pro Woche")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 3)
                            }
                        }
                        .onDelete(perform: deleteHabits)
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingHabit = true
                    } label: {
                        Label("Neuer Habit", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingHabit) {
                AddHabitView()
            }
        }
    }

    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            let habit = habits[index]
            Task { await HabitReminderScheduler.cancel(for: habit) }
            modelContext.delete(habit)
        }
        modelContext.saveIfNeeded()
    }
}

#Preview {
    HabitsView()
        .modelContainer(PreviewData.container)
}
