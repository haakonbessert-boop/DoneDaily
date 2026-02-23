import SwiftData
import SwiftUI

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: [SortDescriptor(\HabitGroup.sortOrder), SortDescriptor(\HabitGroup.createdAt)]) private var groups: [HabitGroup]

    @State private var name = ""
    @State private var icon = "checkmark.seal.fill"
    @State private var color: HabitColor = .blue
    @State private var category: HabitCategory = .health
    @State private var trackingType: HabitTrackingType = .binary
    @State private var dailyTarget = 8
    @State private var target = 5
    @State private var notes = ""
    @State private var selectedGroupID: UUID?
    @State private var isPaused = false
    @State private var pausedUntil = Date()
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var reminderPattern: ReminderPattern = .daily
    @State private var reminderMissedDaysThreshold = 2
    @State private var reminderWeekdays = Set(1...7)
    
    private var canSave: Bool {
        HabitInputValidator.canSave(
            name: name,
            reminderEnabled: reminderEnabled,
            reminderWeekdays: reminderWeekdays
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basis") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("habit_name_field")
                    Stepper("Ziel pro Woche: \(target)", value: $target, in: 1...14)
                    Text("Tipp: Starte lieber klein (z. B. 3x pro Woche).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            .navigationTitle("Neuer Habit")
            .onAppear {
                trackingType = settings.preferredTrackingType
            }
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
                    .accessibilityIdentifier("save_habit_button")
                }
            }
        }
    }

    private func saveHabit() {
        let trimmedName = HabitInputValidator.normalizedName(name)
        guard !trimmedName.isEmpty else { return }

        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let selectedGroup = groups.first { $0.id == selectedGroupID }
        let nextSortOrder = (habitsMaxSortOrder() + 1)
        let habit = Habit(
            name: trimmedName,
            iconName: icon,
            color: color,
            targetPerWeek: target,
            trackingType: trackingType,
            dailyTarget: trackingType == .count ? dailyTarget : 1,
            category: category,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            isPaused: isPaused,
            pausedUntil: isPaused ? Calendar.current.startOfDay(for: pausedUntil) : nil,
            reminderEnabled: reminderEnabled,
            reminderHour: comps.hour ?? 20,
            reminderMinute: comps.minute ?? 0,
            reminderPattern: reminderPattern,
            reminderMissedDaysThreshold: reminderMissedDaysThreshold,
            reminderWeekdays: resolvedWeekdays(),
            sortOrder: nextSortOrder,
            group: selectedGroup
        )

        modelContext.insert(habit)
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

    private func habitsMaxSortOrder() -> Int {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\Habit.sortOrder, order: .reverse)])
        return (try? modelContext.fetch(descriptor).first?.sortOrder) ?? 0
    }
}

#Preview {
    AddHabitView()
        .modelContainer(PreviewData.container)
}
