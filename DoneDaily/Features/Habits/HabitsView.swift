import SwiftData
import SwiftUI

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: [SortDescriptor(\HabitGroup.sortOrder), SortDescriptor(\HabitGroup.createdAt)]) private var groups: [HabitGroup]
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)]) private var habits: [Habit]

    @State private var isAddingHabit = false
    @State private var isQuickAddingHabit = false
    @State private var showAddOptions = false
    @State private var isManagingGroups = false
    @State private var showArchived = false
    @State private var editHabit: Habit?
    @State private var detailGroup: HabitGroup?
    @State private var sortMode: HabitSortMode = .manual

    private var activeHabits: [Habit] {
        habits.filter { !$0.isArchived }
    }

    private var archivedHabits: [Habit] {
        sortHabits(habits.filter(\.isArchived))
    }

    private var suggestions: [HabitSuggestion] {
        HabitSuggestionService.suggestions(for: settings.focusAreas, existingHabits: habits)
    }

    private var groupedActiveHabits: [HabitSection] {
        if sortMode == .colorGroups {
            return colorSections(for: activeHabits)
        }

        var sections: [HabitSection] = []

        for group in groups {
            let grouped = sortHabits(activeHabits.filter { $0.group?.id == group.id })
            if !grouped.isEmpty {
                sections.append(HabitSection(id: group.id.uuidString, title: group.name, habits: grouped, groupID: group.id))
            }
        }

        let ungrouped = sortHabits(activeHabits.filter { $0.group == nil })
        if !ungrouped.isEmpty {
            sections.append(HabitSection(id: "ungrouped", title: "Ohne Gruppe", habits: ungrouped, groupID: nil))
        }

        return sections
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                content

                Button {
                    Haptics.lightImpact()
                    showAddOptions = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(accent)
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.14), radius: 10, x: 0, y: 4)
                }
                .padding(.trailing, AppDesign.screenPadding)
                .padding(.bottom, 20)
                .accessibilityIdentifier("add_habit_fab")
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .background(AppBackgroundView())
            .tint(accent)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(showArchived ? "Archiv aus" : "Archiv ein") {
                        showArchived.toggle()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Menu {
                            Picker("Sortierung", selection: $sortMode) {
                                ForEach(HabitSortMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle")
                        }

                        if sortMode == .manual {
                            EditButton()
                        }

                        Button("Gruppen") {
                            isManagingGroups = true
                        }
                    }
                }
            }
            .confirmationDialog("Habit hinzufügen", isPresented: $showAddOptions, titleVisibility: .visible) {
                Button("Schneller Habit") {
                    isQuickAddingHabit = true
                }
                Button("Vollständig") {
                    isAddingHabit = true
                }
                Button("Abbrechen", role: .cancel) {}
            }
            .sheet(isPresented: $isAddingHabit) {
                AddHabitView()
            }
            .sheet(isPresented: $isQuickAddingHabit) {
                QuickAddHabitSheet()
            }
            .sheet(isPresented: $isManagingGroups) {
                ManageGroupsView()
            }
            .sheet(item: $editHabit) { habit in
                NavigationStack {
                    EditHabitView(habit: habit)
                }
            }
            .sheet(item: $detailGroup) { group in
                NavigationStack {
                    GroupDetailView(group: group)
                }
            }
        }
    }

    private var content: some View {
        List {
            if !suggestions.isEmpty {
                AppCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Vorschläge für dich")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(primaryText)
                        Text("Basierend auf deinen Fokusbereichen")
                            .font(.system(size: 13))
                            .foregroundStyle(secondaryText)

                        ForEach(suggestions.prefix(4)) { suggestion in
                            HStack {
                                Label(suggestion.name, systemImage: suggestion.iconName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(primaryText)
                                Spacer()
                                Button("Hinzufügen") {
                                    addSuggestion(suggestion)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: AppDesign.screenPadding, bottom: 8, trailing: AppDesign.screenPadding))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            if sortMode == .colorGroups && !activeHabits.isEmpty {
                AppCard {
                    ColorLegendRow()
                }
                .listRowInsets(EdgeInsets(top: 8, leading: AppDesign.screenPadding, bottom: 8, trailing: AppDesign.screenPadding))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            if activeHabits.isEmpty && !(showArchived && !archivedHabits.isEmpty) {
                AppCard {
                    Text("Erstelle einen Habit, um loszulegen.")
                        .foregroundStyle(secondaryText)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: AppDesign.screenPadding, bottom: 8, trailing: AppDesign.screenPadding))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedActiveHabits) { section in
                    Section {
                        ForEach(section.habits) { habit in
                            habitRow(habit, archived: false)
                                .listRowInsets(EdgeInsets(top: 7, leading: AppDesign.screenPadding, bottom: 7, trailing: AppDesign.screenPadding))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .onMove { source, destination in
                            moveHabits(in: section, from: source, to: destination)
                        }
                    } header: {
                        HStack {
                            Text(section.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(secondaryText)
                                .textCase(nil)
                            Spacer()
                            if let groupID = section.groupID,
                               let group = groups.first(where: { $0.id == groupID }) {
                                Button("Details") {
                                    detailGroup = group
                                }
                                .font(.system(size: 12, weight: .semibold))
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .moveDisabled(sortMode != .manual)
                }

                if showArchived && !archivedHabits.isEmpty {
                    Section {
                        ForEach(archivedHabits) { habit in
                            habitRow(habit, archived: true)
                                .listRowInsets(EdgeInsets(top: 7, leading: AppDesign.screenPadding, bottom: 7, trailing: AppDesign.screenPadding))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text("Archiv")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(primaryText)
                            .textCase(nil)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 88)
        }
    }

    private func habitRow(_ habit: Habit, archived: Bool) -> some View {
        let weeklyDone = habit.completedThisWeek(weekStart: settings.weekStart.rawValue)
        return AppCard {
            HStack(spacing: 14) {
                MiniProgressRing(progress: Double(weeklyDone) / Double(max(1, habit.targetPerWeek)))

                VStack(alignment: .leading, spacing: 8) {
                    Text(habit.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(primaryText)
                    WeekDotsView(completed: weeklyDone, target: habit.targetPerWeek)
                    Text("\(habit.category.title) · Ziel \(habit.targetPerWeek)x")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if habit.trackingType == .count {
                        HStack(spacing: 8) {
                            Button {
                                decrementTodayProgress(habit)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .disabled(archived || habit.dailyProgress(on: .now) == 0)

                            Text("\(habit.dailyProgress(on: .now))/\(habit.dailyTarget)")
                                .font(.system(size: 15, weight: .semibold))
                                .monospacedDigit()

                            Button {
                                incrementTodayProgress(habit)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .disabled(archived || habit.dailyProgress(on: .now) >= habit.dailyTarget)
                        }
                        .foregroundStyle(primaryText)
                    } else {
                        Button {
                            toggleTodayCompletion(habit)
                        } label: {
                            Image(systemName: habit.isCompleted(on: .now) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(habit.isCompleted(on: .now) ? accent : secondaryText)
                        }
                        .buttonStyle(.plain)
                        .disabled(archived)

                        Text("Heute")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(secondaryText)
                    }
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                if archived {
                    deleteHabit(habit)
                } else {
                    archiveHabit(habit)
                }
            } label: {
                Text("Delete")
            }

            Button {
                editHabit = habit
            } label: {
                Text("Edit")
            }
            .tint(.gray)
        }
        .onTapGesture {
            editHabit = habit
        }
    }

    private func toggleTodayCompletion(_ habit: Habit) {
        guard !habit.isArchived else { return }
        habit.toggleCompletion(on: .now)
        if modelContext.saveIfNeeded() {
            Haptics.lightImpact()
        }
    }

    private func incrementTodayProgress(_ habit: Habit) {
        guard !habit.isArchived else { return }
        habit.incrementProgress(on: .now)
        if modelContext.saveIfNeeded() {
            Haptics.lightImpact()
        }
    }

    private func decrementTodayProgress(_ habit: Habit) {
        guard !habit.isArchived else { return }
        habit.decrementProgress(on: .now)
        if modelContext.saveIfNeeded() {
            Haptics.lightImpact()
        }
    }

    private func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        Task { await HabitReminderScheduler.scheduleIfEnabled(for: habit) }
        if modelContext.saveIfNeeded() {
            Haptics.lightImpact()
        }
    }

    private func deleteHabit(_ habit: Habit) {
        Task { await HabitReminderScheduler.cancel(for: habit) }
        modelContext.delete(habit)
        if modelContext.saveIfNeeded() {
            Haptics.lightImpact()
        }
    }

    private func addSuggestion(_ suggestion: HabitSuggestion) {
        let nextSortOrder = ((try? modelContext.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\Habit.sortOrder, order: .reverse)])).first?.sortOrder) ?? 0) + 1
        let habit = Habit(
            name: suggestion.name,
            iconName: suggestion.iconName,
            color: suggestion.color,
            targetPerWeek: suggestion.targetPerWeek,
            trackingType: suggestion.trackingType,
            dailyTarget: suggestion.dailyTarget,
            category: suggestion.category,
            sortOrder: nextSortOrder
        )
        modelContext.insert(habit)
        if modelContext.saveIfNeeded() {
            Haptics.success()
        }
    }

    private func moveHabits(in section: HabitSection, from source: IndexSet, to destination: Int) {
        guard sortMode == .manual else { return }

        var sectionHabits = section.habits
        sectionHabits.move(fromOffsets: source, toOffset: destination)

        for (index, habit) in sectionHabits.enumerated() {
            habit.sortOrder = index
            habit.group = groups.first(where: { $0.id == section.groupID })
        }

        if modelContext.saveIfNeeded() {
            Haptics.lightImpact()
        }
    }

    private func colorSections(for habits: [Habit]) -> [HabitSection] {
        HabitColor.allCases.compactMap { color in
            let values = habits
                .filter { $0.color == color }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            guard !values.isEmpty else { return nil }
            return HabitSection(id: "color-\(color.rawValue)", title: color.title, habits: values, groupID: nil)
        }
    }

    private func sortHabits(_ values: [Habit]) -> [Habit] {
        switch sortMode {
        case .manual:
            return values.sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.createdAt < $1.createdAt
                }
                return $0.sortOrder < $1.sortOrder
            }
        case .createdAt:
            return values.sorted { $0.createdAt < $1.createdAt }
        case .name:
            return values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .color:
            return values.sorted { lhs, rhs in
                let left = lhs.color.sortIndex
                let right = rhs.color.sortIndex
                if left == right {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return left < right
            }
        case .streak:
            return values.sorted { lhs, rhs in
                if lhs.streak() == rhs.streak() {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.streak() > rhs.streak()
            }
        case .colorGroups:
            return values
        }
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

#Preview {
    HabitsView()
        .modelContainer(PreviewData.container)
}

private struct HabitSuggestion: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let color: HabitColor
    let category: HabitCategory
    let targetPerWeek: Int
    let trackingType: HabitTrackingType
    let dailyTarget: Int
}

private struct HabitSection: Identifiable {
    let id: String
    let title: String
    let habits: [Habit]
    let groupID: UUID?
}

private enum HabitSortMode: String, CaseIterable, Identifiable {
    case manual
    case createdAt
    case name
    case color
    case colorGroups
    case streak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual:
            return "Manuell"
        case .createdAt:
            return "Neueste"
        case .name:
            return "Name"
        case .color:
            return "Farbe"
        case .colorGroups:
            return "Farbfamilien"
        case .streak:
            return "Streak"
        }
    }
}

private struct ColorLegendRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Farblegende")
                .font(.system(size: 15, weight: .semibold))
            HStack(spacing: 12) {
                ForEach(HabitColor.allCases) { color in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 8, height: 8)
                        Text(color.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct QuickAddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\HabitGroup.sortOrder), SortDescriptor(\HabitGroup.createdAt)]) private var groups: [HabitGroup]

    @State private var name = ""
    @State private var color: HabitColor = .blue
    @State private var target = 5
    @State private var trackingType: HabitTrackingType = .binary
    @State private var dailyTarget = 8
    @State private var selectedGroupID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("Schneller Habit") {
                    TextField("Name", text: $name)
                    Stepper("Ziel pro Woche: \(target)", value: $target, in: 1...14)
                    Picker("Farbe", selection: $color) {
                        ForEach(HabitColor.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    Picker("Gruppe", selection: $selectedGroupID) {
                        Text("Keine").tag(Optional<UUID>.none)
                        ForEach(groups) { group in
                            Text(group.name).tag(Optional(group.id))
                        }
                    }
                    Picker("Tracking", selection: $trackingType) {
                        ForEach(HabitTrackingType.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    if trackingType == .count {
                        Stepper("Tagesziel: \(dailyTarget)", value: $dailyTarget, in: 2...20)
                    }
                }
            }
            .navigationTitle("Quick Add")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let maxSortOrder = (try? modelContext.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\Habit.sortOrder, order: .reverse)])).first?.sortOrder) ?? 0

        let habit = Habit(
            name: trimmed,
            iconName: "checkmark.seal.fill",
            color: color,
            targetPerWeek: target,
            trackingType: trackingType,
            dailyTarget: trackingType == .count ? dailyTarget : 1,
            category: .other,
            sortOrder: maxSortOrder + 1,
            group: groups.first(where: { $0.id == selectedGroupID })
        )

        modelContext.insert(habit)
        if modelContext.saveIfNeeded() {
            Haptics.success()
        }
        dismiss()
    }
}

private struct GroupDetailView: View {
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)]) private var habits: [Habit]
    let group: HabitGroup

    private var groupRows: [GroupHabitRow] {
        habits
            .filter { $0.group?.id == group.id && !$0.isArchived }
            .map { GroupHabitRow(id: $0.id, name: $0.name, streak: $0.streak(), ratio: $0.progressRatio(on: .now)) }
    }

    private var completionToday: Double {
        guard !groupRows.isEmpty else { return 0 }
        let sum = groupRows.reduce(0.0) { partial, row in
            partial + row.ratio
        }
        return sum / Double(groupRows.count)
    }

    var body: some View {
        List {
            Section("Heute") {
                Text("\(Int((completionToday * 100).rounded()))% erfüllt")
                Text("\(groupRows.count) aktive Habits")
            }
            Section("Habits") {
                if groupRows.isEmpty {
                    Text("Keine aktiven Habits in dieser Gruppe.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(groupRows) { row in
                        HStack {
                            Text(row.name)
                            Spacer()
                            Text("\(row.streak)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GroupHabitRow: Identifiable {
    let id: UUID
    let name: String
    let streak: Int
    let ratio: Double
}

private enum HabitSuggestionService {
    nonisolated static func suggestions(for focusAreas: [FocusArea], existingHabits: [Habit]) -> [HabitSuggestion] {
        let existingNames = Set(existingHabits.map { normalized($0.name) })
        let raw = focusAreas.flatMap(suggestions(for:))
        var unique: [HabitSuggestion] = []
        var seen = Set<String>()

        for suggestion in raw {
            let key = normalized(suggestion.name)
            guard !seen.contains(key), !existingNames.contains(key) else { continue }
            seen.insert(key)
            unique.append(suggestion)
        }

        return Array(unique.prefix(8))
    }

    private nonisolated static func suggestions(for area: FocusArea) -> [HabitSuggestion] {
        switch area {
        case .health:
            return [
                .init(id: "water", name: "2L Wasser trinken", iconName: "drop.fill", color: .blue, category: .health, targetPerWeek: 7, trackingType: .count, dailyTarget: 8),
                .init(id: "walk", name: "20 Min Spaziergang", iconName: "figure.walk", color: .green, category: .health, targetPerWeek: 5, trackingType: .binary, dailyTarget: 1)
            ]
        case .fitness:
            return [
                .init(id: "workout", name: "Workout", iconName: "figure.run", color: .green, category: .fitness, targetPerWeek: 4, trackingType: .binary, dailyTarget: 1),
                .init(id: "stretch", name: "Dehnen", iconName: "figure.cooldown", color: .orange, category: .fitness, targetPerWeek: 5, trackingType: .binary, dailyTarget: 1)
            ]
        case .learning:
            return [
                .init(id: "read10", name: "10 Minuten Lesen", iconName: "book.fill", color: .blue, category: .learning, targetPerWeek: 5, trackingType: .binary, dailyTarget: 1),
                .init(id: "language", name: "Vokabeln lernen", iconName: "character.book.closed", color: .pink, category: .learning, targetPerWeek: 6, trackingType: .binary, dailyTarget: 1)
            ]
        case .mindfulness:
            return [
                .init(id: "breathe", name: "5 Min Atemübung", iconName: "wind", color: .pink, category: .mindfulness, targetPerWeek: 7, trackingType: .binary, dailyTarget: 1),
                .init(id: "journal", name: "Journaling", iconName: "pencil.and.scribble", color: .orange, category: .mindfulness, targetPerWeek: 4, trackingType: .binary, dailyTarget: 1)
            ]
        case .productivity:
            return [
                .init(id: "deepwork", name: "Deep Work Block", iconName: "timer", color: .green, category: .productivity, targetPerWeek: 5, trackingType: .binary, dailyTarget: 1),
                .init(id: "plan", name: "Tagesplanung", iconName: "checklist", color: .blue, category: .productivity, targetPerWeek: 7, trackingType: .binary, dailyTarget: 1)
            ]
        case .adhd:
            return [
                .init(id: "pomodoro", name: "25 Min Fokus-Sprint", iconName: "timer.circle.fill", color: .red, category: .productivity, targetPerWeek: 5, trackingType: .binary, dailyTarget: 1),
                .init(id: "braindump", name: "5 Min Brain Dump", iconName: "note.text", color: .orange, category: .mindfulness, targetPerWeek: 7, trackingType: .binary, dailyTarget: 1),
                .init(id: "reset2min", name: "2-Minuten Reset", iconName: "sparkles", color: .pink, category: .productivity, targetPerWeek: 7, trackingType: .binary, dailyTarget: 1),
                .init(id: "medication", name: "Medikamenten-Check", iconName: "pills.fill", color: .blue, category: .health, targetPerWeek: 7, trackingType: .binary, dailyTarget: 1),
                .init(id: "plan3", name: "3 Prioritäten festlegen", iconName: "list.number", color: .green, category: .productivity, targetPerWeek: 7, trackingType: .binary, dailyTarget: 1),
                .init(id: "tidy10", name: "10 Min Aufräum-Reset", iconName: "tray.full.fill", color: .orange, category: .productivity, targetPerWeek: 5, trackingType: .binary, dailyTarget: 1),
                .init(id: "bodydouble", name: "Body Doubling Session", iconName: "person.2.fill", color: .blue, category: .productivity, targetPerWeek: 3, trackingType: .binary, dailyTarget: 1),
                .init(id: "winddown", name: "Abend-Winddown 20 Min", iconName: "moon.stars.fill", color: .pink, category: .mindfulness, targetPerWeek: 5, trackingType: .binary, dailyTarget: 1)
            ]
        case .sleep:
            return [
                .init(id: "sleep", name: "Vor 23 Uhr schlafen", iconName: "bed.double.fill", color: .pink, category: .health, targetPerWeek: 6, trackingType: .binary, dailyTarget: 1),
                .init(id: "screenoff", name: "Kein Screen 30 Min vorher", iconName: "moon.zzz.fill", color: .orange, category: .mindfulness, targetPerWeek: 6, trackingType: .binary, dailyTarget: 1)
            ]
        }
    }

    private nonisolated static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private extension HabitColor {
    var sortIndex: Int {
        switch self {
        case .blue: return 0
        case .green: return 1
        case .orange: return 2
        case .red: return 3
        case .pink: return 4
        }
    }

    var title: String {
        switch self {
        case .blue: return "Blau"
        case .green: return "Grün"
        case .orange: return "Orange"
        case .red: return "Rot"
        case .pink: return "Pink"
        }
    }
}
