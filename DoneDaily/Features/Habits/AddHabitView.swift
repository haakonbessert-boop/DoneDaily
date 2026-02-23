import SwiftData
import SwiftUI

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "checkmark.seal.fill"
    @State private var color: HabitColor = .blue
    @State private var target = 5
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var reminderWeekdays = Set(1...7)
    
    private var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasReminderDay = !reminderEnabled || !reminderWeekdays.isEmpty
        return hasName && hasReminderDay
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basis") {
                    TextField("Name", text: $name)
                    Stepper("Ziel pro Woche: \(target)", value: $target, in: 1...14)
                    Text("Tipp: Starte lieber klein (z. B. 3x pro Woche).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            .navigationTitle("Neuer Habit")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        saveHabit()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let habit = Habit(
            name: trimmedName,
            iconName: icon,
            color: color,
            targetPerWeek: target,
            reminderEnabled: reminderEnabled,
            reminderHour: comps.hour ?? 20,
            reminderMinute: comps.minute ?? 0,
            reminderWeekdays: reminderWeekdays
        )

        modelContext.insert(habit)
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
    AddHabitView()
        .modelContainer(PreviewData.container)
}
