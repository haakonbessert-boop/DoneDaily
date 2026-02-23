import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: [SortDescriptor(\HabitGroup.sortOrder), SortDescriptor(\HabitGroup.createdAt)]) private var groups: [HabitGroup]
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)]) private var habits: [Habit]

    @State private var mode: TodayMode = .overview
    @State private var lastToggle: (habit: Habit, previousProgress: Int)?
    @State private var undoToastVisible = false
    @State private var recentlyCompletedHabitID: UUID?

    private var activeHabits: [Habit] {
        habits.filter(\.isActive)
    }

    private var dueTodayHabits: [Habit] {
        activeHabits.filter { $0.isDue(on: .now) }
    }

    private var groupedTodayHabits: [TodayHabitSection] {
        var sections: [TodayHabitSection] = []

        for group in groups {
            let grouped = dueTodayHabits.filter { $0.group?.id == group.id }
            if !grouped.isEmpty {
                sections.append(TodayHabitSection(id: group.id.uuidString, title: group.name, habits: grouped))
            }
        }

        let ungrouped = dueTodayHabits.filter { $0.group == nil }
        if !ungrouped.isEmpty {
            sections.append(TodayHabitSection(id: "ungrouped", title: "Ohne Gruppe", habits: ungrouped))
        }

        return sections
    }

    private var focusHabit: Habit? {
        dueTodayHabits
            .sorted { lhs, rhs in
                if lhs.isCompleted(on: .now) == rhs.isCompleted(on: .now) {
                    return lhs.streak() > rhs.streak()
                }
                return !lhs.isCompleted(on: .now)
            }
            .first
    }

    private var calculator: HabitStatsCalculator {
        HabitStatsCalculator(habits: activeHabits, weekStart: settings.weekStart)
    }

    private var completion7Days: Int {
        Int((calculator.completionRateThisWeek * 100).rounded())
    }

    private var longestCurrentStreak: Int {
        activeHabits.map { $0.streak() }.max() ?? 0
    }

    private var doneTodayCount: Int {
        dueTodayHabits.filter { $0.isCompleted(on: .now) }.count
    }

    private var todayCompletionRatio: Double {
        guard !dueTodayHabits.isEmpty else { return 0 }
        return Double(doneTodayCount) / Double(dueTodayHabits.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppDesign.stackSpacing) {
                    modeSegment

                    if activeHabits.isEmpty {
                        AppCard {
                            Text("Lege deinen ersten Habit im Habits-Tab an.")
                                .foregroundStyle(secondaryText)
                        }
                    } else if dueTodayHabits.isEmpty {
                        AppCard {
                            Text("Heute sind keine Habits fällig.")
                                .foregroundStyle(secondaryText)
                        }
                    } else if mode == .overview {
                        overviewContent
                    } else {
                        focusContent
                    }
                }
                .padding(.horizontal, AppDesign.screenPadding)
                .padding(.bottom, 32)
            }
            .overlay(alignment: .bottom) {
                if undoToastVisible, let lastToggle {
                    UndoToast(
                        title: "\(lastToggle.habit.name) aktualisiert",
                        action: undoLastToggle
                    )
                    .padding(.horizontal, AppDesign.screenPadding)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(AppBackgroundView())
            .navigationTitle("Heute")
            .navigationBarTitleDisplayMode(.large)
            .tint(accent)
        }
    }

    private var modeSegment: some View {
        Picker(
            "Ansicht",
            selection: reduceMotion ? $mode : $mode.animation(.easeInOut(duration: 0.2))
        ) {
            ForEach(TodayMode.allCases) { value in
                Text(value.title).tag(value)
            }
        }
        .pickerStyle(.segmented)
    }

    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: AppDesign.stackSpacing) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                kpiCard(title: "7-Tage Completion", value: "\(completion7Days)%")
                kpiCard(title: "Heute erledigt", value: "\(doneTodayCount)/\(dueTodayHabits.count)")
                kpiCard(title: "Aktuelle Streak", value: "\(longestCurrentStreak) Tage")
                kpiCard(title: "Heute fällig", value: "\(dueTodayHabits.count)")
            }

            Text("Heute fällig")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(primaryText)

            AppCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Tagesfortschritt")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(secondaryText)
                        Spacer()
                        Text("\(doneTodayCount) / \(dueTodayHabits.count)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(primaryText)
                            .contentTransition(.numericText())
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(secondaryText.opacity(0.16))
                            Capsule()
                                .fill(accent)
                                .frame(width: proxy.size.width * todayCompletionRatio)
                        }
                    }
                    .frame(height: 8)
                    .animation(.easeInOut(duration: 0.25), value: todayCompletionRatio)
                }
            }

            VStack(spacing: 14) {
                ForEach(groupedTodayHabits) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(secondaryText)

                        VStack(spacing: 10) {
                            ForEach(
                                section.habits.sorted { lhs, rhs in
                                    if lhs.isCompleted(on: .now) == rhs.isCompleted(on: .now) {
                                        return lhs.name.localizedCompare(rhs.name) == .orderedAscending
                                    }
                                    return !lhs.isCompleted(on: .now)
                                }
                            ) { habit in
                                habitCard(habit)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                }
            }
        }
    }

    private func kpiCard(title: String, value: String) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(secondaryText)
                Text(value)
                    .font(.system(size: 29, weight: .semibold))
                    .foregroundStyle(primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func habitCard(_ habit: Habit) -> some View {
        let isDoneToday = habit.isCompleted(on: .now)
        let dailyRatio = habit.progressRatio(on: .now)
        let dailyProgress = habit.dailyProgress(on: .now)
        let dailyGoal = max(1, habit.trackingType == .binary ? 1 : habit.dailyTarget)

        return AppCard {
            HStack(spacing: 14) {
                if isDoneToday {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(accent)
                        .scaleEffect(recentlyCompletedHabitID == habit.id ? 1.12 : 1.0)
                        .symbolEffect(.bounce, value: recentlyCompletedHabitID == habit.id)
                } else {
                    MiniProgressRing(progress: dailyRatio)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(habit.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(primaryText)
                    Text(isDoneToday ? "Heute erledigt" : "Heute offen")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(isDoneToday ? accent : secondaryText)
                }

                Spacer()

                if habit.trackingType == .count {
                    CountProgressControl(
                        progress: habit.dailyProgress(on: .now),
                        target: habit.dailyTarget,
                        onMinus: { decrement(habit) },
                        onPlus: { increment(habit) }
                    )
                } else {
                    Button {
                        toggle(habit)
                    } label: {
                        VStack(alignment: .trailing, spacing: 2) {
                            Image(systemName: isDoneToday ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(isDoneToday ? accent : secondaryText)
                                .scaleEffect(recentlyCompletedHabitID == habit.id ? 1.12 : 1.0)
                                .symbolEffect(.bounce, value: recentlyCompletedHabitID == habit.id)
                            Text("\(habit.streak()) Tage")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(secondaryText)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("today_toggle_\(habit.id.uuidString)")
                    .accessibilityLabel("\(habit.name) abschließen")
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppDesign.cornerRadiusCard, style: .continuous)
                .fill(isDoneToday ? accent.opacity(0.10) : .clear)
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppDesign.cornerRadiusCard, style: .continuous)
                .stroke(isDoneToday ? accent.opacity(0.22) : .clear, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isDoneToday)
        .animation(.easeInOut(duration: 0.2), value: dailyProgress)
        .accessibilityValue("\(dailyProgress) von \(dailyGoal) erledigt")
    }

    private var focusContent: some View {
        VStack(spacing: AppDesign.stackSpacing) {
            if let habit = focusHabit ?? dueTodayHabits.first {
                let progressRatio = habit.progressRatio(on: .now)
                let isDoneToday = habit.isCompleted(on: .now)
                AppCard(padding: 32, cornerRadius: AppDesign.cornerRadiusLargeCard) {
                    VStack(spacing: 20) {
                        Text(habit.name)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(primaryText)
                            .multilineTextAlignment(.center)

                        LargeProgressRing(progress: progressRatio)

                        Text("\(habit.streak()) Tage Streak")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(primaryText)

                        Button {
                            toggle(habit)
                        } label: {
                            Text(habit.trackingType == .count ? "Fortschritt +1" : (isDoneToday ? "Heute erledigt" : "Heute abhaken"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(habit.trackingType == .binary && isDoneToday)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                AppCard {
                    Text("Heute sind keine Habits für den Fokus-Modus fällig.")
                        .foregroundStyle(secondaryText)
                }
            }
        }
    }

    private func toggle(_ habit: Habit) {
        if habit.trackingType == .count {
            increment(habit)
            return
        }
        let previousProgress = habit.dailyProgress(on: .now)
        let wasCompleted = habit.isCompleted(on: .now)
        habit.toggleCompletion()
        if modelContext.saveIfNeeded() {
            let isCompleted = habit.isCompleted(on: .now)
            if !wasCompleted, isCompleted {
                markRecentlyCompleted(habit.id)
                Haptics.success()
            } else {
                Haptics.lightImpact()
            }
            lastToggle = (habit: habit, previousProgress: previousProgress)
            showUndoToast()
        }
    }

    private func undoLastToggle() {
        guard let lastToggle else { return }
        lastToggle.habit.setProgress(lastToggle.previousProgress)
        if modelContext.saveIfNeeded() {
            self.lastToggle = nil
            withAnimation(.easeInOut(duration: 0.2)) {
                undoToastVisible = false
            }
        }
    }

    private func increment(_ habit: Habit) {
        let previousProgress = habit.dailyProgress(on: .now)
        let wasCompleted = habit.isCompleted(on: .now)
        habit.incrementProgress()
        if modelContext.saveIfNeeded() {
            let isCompleted = habit.isCompleted(on: .now)
            if !wasCompleted, isCompleted {
                markRecentlyCompleted(habit.id)
                Haptics.success()
            } else {
                Haptics.lightImpact()
            }
            lastToggle = (habit: habit, previousProgress: previousProgress)
            showUndoToast()
        }
    }

    private func decrement(_ habit: Habit) {
        let previousProgress = habit.dailyProgress(on: .now)
        habit.decrementProgress()
        if modelContext.saveIfNeeded() {
            Haptics.lightImpact()
            lastToggle = (habit: habit, previousProgress: previousProgress)
            showUndoToast()
        }
    }

    private func showUndoToast() {
        withAnimation(.easeInOut(duration: 0.2)) {
            undoToastVisible = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard undoToastVisible else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                undoToastVisible = false
            }
        }
    }

    private func markRecentlyCompleted(_ habitID: UUID) {
        recentlyCompletedHabitID = habitID
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            guard recentlyCompletedHabitID == habitID else { return }
            recentlyCompletedHabitID = nil
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

private enum TodayMode: String, CaseIterable, Identifiable {
    case overview
    case focus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview:
            return "Übersicht"
        case .focus:
            return "Fokus"
        }
    }
}

private struct TodayHabitSection: Identifiable {
    let id: String
    let title: String
    let habits: [Habit]
}

private struct UndoToast: View {
    let title: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
            Spacer()
            Button("Undo") {
                action()
            }
            .font(.system(size: 14, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct CountProgressControl: View {
    let progress: Int
    let target: Int
    let onMinus: () -> Void
    let onPlus: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onMinus) {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 26, height: 26)
                    .background(.secondary.opacity(0.14), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(progress == 0)

            Text("\(progress)/\(target)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .frame(minWidth: 52)
                .contentTransition(.numericText())

            Button(action: onPlus) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 26, height: 26)
                    .background(.secondary.opacity(0.14), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(progress >= target)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.secondary.opacity(0.08), in: Capsule())
        .animation(.easeInOut(duration: 0.2), value: progress)
    }
}

#Preview {
    TodayView()
        .environmentObject(AppSettings())
        .modelContainer(PreviewData.container)
}
