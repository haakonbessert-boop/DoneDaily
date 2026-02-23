import SwiftData
import SwiftUI

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let habit: Habit

    @State private var name: String
    @State private var icon: String
    @State private var color: HabitColor
    @State private var target: Int
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var reminderWeekdays: Set<Int>
    
    private var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasReminderDay = !reminderEnabled || !reminderWeekdays.isEmpty
        return hasName && hasReminderDay
    }

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _icon = State(initialValue: habit.iconName)
        _color = State(initialValue: habit.color)
        _target = State(initialValue: habit.targetPerWeek)
        _reminderEnabled = State(initialValue: habit.reminderEnabled)

        var components = DateComponents()
        components.hour = habit.reminderHour
        components.minute = habit.reminderMinute
        let date = Calendar.current.date(from: components) ?? .now
        _reminderTime = State(initialValue: date)

        _reminderWeekdays = State(initialValue: habit.reminderWeekdays)
    }

    var body: some View {
        Form {
            Section("Basis") {
                TextField("Name", text: $name)
                Stepper("Ziel pro Woche: \(target)", value: $target, in: 1...14)
            }

            Section("Farbe") {
                Picker("Farbe", selection: $color) {
                    ForEach(HabitColor.allCases) { item in
                        Text(item.rawValue.capitalized)
                            .tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Icon") {
                Picker("Icon", selection: $icon) {
                    ForEach(HabitFormOptions.suggestedIcons, id: \.self) { symbol in
                        Label(symbol, systemImage: symbol)
                            .tag(symbol)
                    }
                }
            }

            Section("Reminder") {
                Toggle("Erinnerung aktiv", isOn: $reminderEnabled)

                if reminderEnabled {
                    DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wochentage")
                            .font(.subheadline)
                        WeekdayPickerView(selectedWeekdays: $reminderWeekdays)
                    }
                }
            }
        }
        .navigationTitle("Habit bearbeiten")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Speichern") {
                    saveChanges()
                }
                .disabled(!canSave)
            }
        }
    }

    private func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)

        habit.name = trimmedName
        habit.iconName = icon
        habit.color = color
        habit.targetPerWeek = max(1, target)
        habit.reminderEnabled = reminderEnabled
        habit.reminderHour = components.hour ?? 20
        habit.reminderMinute = components.minute ?? 0
        habit.reminderWeekdays = reminderWeekdays

        modelContext.saveIfNeeded()

        Task {
            if reminderEnabled {
                _ = try? await HabitReminderScheduler.requestAuthorization()
            }
            await HabitReminderScheduler.scheduleIfEnabled(for: habit)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        EditHabitView(
            habit: Habit(name: "Lesen", iconName: "book.fill", color: .blue, targetPerWeek: 5)
        )
    }
    .modelContainer(PreviewData.container)
}
