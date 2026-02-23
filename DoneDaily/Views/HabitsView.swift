import SwiftData
import SwiftUI

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var isAddingHabit = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
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
                .onDelete(perform: deleteHabits)
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
            modelContext.delete(habits[index])
        }
        modelContext.saveIfNeeded()
    }
}

#Preview {
    HabitsView()
        .modelContainer(PreviewData.container)
}
