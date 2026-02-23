import SwiftData
import SwiftUI

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\HabitGroup.sortOrder), SortDescriptor(\HabitGroup.createdAt)]) private var groups: [HabitGroup]

    let habit: Habit

    @State private var name: String
    @State private var icon: String
    @State private var color: HabitColor
    @State private var category: HabitCategory
    @State private var trackingType: HabitTrackingType
    @State private var dailyTarget: Int
    @State private var target: Int
    @State private var notes: String
    @State private var selectedGroupID: UUID?
    @State private var isArchived: Bool
    @State private var isPaused: Bool
    @State private var pausedUntil: Date
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var reminderPattern: ReminderPattern
    @State private var reminderMissedDaysThreshold: Int
    @State private var reminderWeekdays: Set<Int>
    
    private var canSave: Bool {
        HabitInputValidator.canSave(
            name: name,
            reminderEnabled: reminderEnabled,
            reminderWeekdays: reminderWeekdays
        )
    }

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _icon = State(initialValue: habit.iconName)
        _color = State(initialValue: habit.color)
        _category = State(initialValue: habit.category)
        _trackingType = State(initialValue: habit.trackingType)
        _dailyTarget = State(initialValue: habit.dailyTarget)
        _target = State(initialValue: habit.targetPerWeek)
        _notes = State(initialValue: habit.notes)
        _selectedGroupID = State(initialValue: habit.group?.id)
        _isArchived = State(initialValue: habit.isArchived)
        _isPaused = State(initialValue: habit.isPaused)
        _pausedUntil = State(initialValue: habit.pausedUntil ?? .now)
        _reminderEnabled = State(initialValue: habit.reminderEnabled)

        var components = DateComponents()
        components.hour = habit.reminderHour
        components.minute = habit.reminderMinute
        let date = Calendar.current.date(from: components) ?? .now
        _reminderTime = State(initialValue: date)
        _reminderPattern = State(initialValue: habit.reminderPattern)
        _reminderMissedDaysThreshold = State(initialValue: habit.reminderMissedDaysThreshold)

        _reminderWeekdays = State(initialValue: habit.reminderWeekdays)
    }

    var body: some View {
        Form {
            Section("Basis") {
                TextField("Name", text: $name)
                Stepper("Ziel pro Woche: \(target)", value: $target, in: 1...14)
            }

            Section("Einordnung") {
                Picker("Tracking", selection: $trackingType) {
                    ForEach(HabitTrackingType.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }

                if trackingType == .count {
                    Stepper("Tagesziel: \(dailyTarget)", value: $dailyTarget, in: 2...20)
                }

                Picker("Kategorie", selection: $category) {
                    ForEach(HabitCategory.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }

                Picker("Gruppe", selection: $selectedGroupID) {
                    Text("Keine").tag(Optional<UUID>.none)
                    ForEach(groups) { group in
                        Text(group.name).tag(Optional(group.id))
                    }
                }

                TextField("Notizen (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Status") {
                Toggle("Archiviert", isOn: $isArchived)
                Toggle("Habit pausieren", isOn: $isPaused)
                if isPaused {
                    DatePicker("Pausiert bis", selection: $pausedUntil, displayedComponents: .date)
                }
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
                    Picker("Muster", selection: $reminderPattern) {
                        ForEach(ReminderPattern.allCases) { pattern in
                            Text(pattern.title).tag(pattern)
                        }
                    }

                    DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)

                    if reminderPattern == .afterMissedDays {
                        Stepper("Nudge nach \(reminderMissedDaysThreshold) verpassten Tagen", value: $reminderMissedDaysThreshold, in: 1...5)
                    }

                    if reminderPattern == .weekdays {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Wochentage")
                                .font(.subheadline)
                            WeekdayPickerView(selectedWeekdays: $reminderWeekdays)
                        }
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
        let trimmedName = HabitInputValidator.normalizedName(name)
        guard !trimmedName.isEmpty else { return }

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)

        habit.name = trimmedName
        habit.iconName = icon
        habit.color = color
        habit.category = category
        habit.trackingType = trackingType
        habit.dailyTarget = trackingType == .count ? max(2, dailyTarget) : 1
        habit.group = groups.first { $0.id == selectedGroupID }
        habit.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        habit.isArchived = isArchived
        habit.isPaused = isPaused
        habit.pausedUntil = isPaused ? Calendar.current.startOfDay(for: pausedUntil) : nil
        habit.targetPerWeek = max(1, target)
        habit.reminderEnabled = reminderEnabled
        habit.reminderHour = components.hour ?? 20
        habit.reminderMinute = components.minute ?? 0
        habit.reminderPattern = reminderPattern
        habit.reminderMissedDaysThreshold = max(1, reminderMissedDaysThreshold)
        habit.reminderWeekdays = resolvedWeekdays()

        if modelContext.saveIfNeeded() {
            Haptics.success()
        }

        Task {
            if reminderEnabled {
                _ = try? await HabitReminderScheduler.requestAuthorization()
            }
            await HabitReminderScheduler.scheduleIfEnabled(for: habit)
        }

        dismiss()
    }

    private func resolvedWeekdays() -> Set<Int> {
        switch reminderPattern {
        case .weekdays:
            return reminderWeekdays
        case .daily, .gentleEvening, .afterMissedDays:
            return Set(1...7)
        }
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
