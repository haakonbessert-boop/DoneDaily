import SwiftUI

struct OnboardingSelection {
    let weekStart: WeekStart
    let focusAreas: [FocusArea]
    let groupPresets: [OnboardingGroupPreset]
    let preferredTrackingType: HabitTrackingType
    let requestReminders: Bool
}

struct OnboardingView: View {
    let initialWeekStart: WeekStart
    let initialFocusAreas: [FocusArea]
    let onContinue: (OnboardingSelection) -> Void

    @State private var step: OnboardingStep = .intro
    @State private var weekStart: WeekStart
    @State private var selectedFocusAreas: Set<FocusArea>
    @State private var selectedGroupPresets: Set<OnboardingGroupPreset> = [.health, .focus, .lifestyle]
    @State private var preferredTrackingType: HabitTrackingType = .binary
    @State private var requestReminders = true

    init(
        initialWeekStart: WeekStart,
        initialFocusAreas: [FocusArea],
        onContinue: @escaping (OnboardingSelection) -> Void
    ) {
        self.initialWeekStart = initialWeekStart
        self.initialFocusAreas = initialFocusAreas
        self.onContinue = onContinue
        _weekStart = State(initialValue: initialWeekStart)
        _selectedFocusAreas = State(initialValue: Set(initialFocusAreas))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(step.title)
                        .font(.system(size: 30, weight: .bold))
                        .padding(.top, 8)

                    Text(step.subtitle)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.secondary)

                    content
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            bottomBar
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: step)
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                if step != .intro {
                    Button {
                        goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                    }
                } else {
                    Color.clear.frame(width: 24, height: 24)
                }

                Spacer()

                Text("\(step.index + 1)/\(OnboardingStep.allCases.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(step.index + 1), total: Double(OnboardingStep.allCases.count))
                .tint(.accentColor)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .intro:
            VStack(spacing: 12) {
                featureCard(icon: "checkmark.circle.fill", title: "Einfach tracken", subtitle: "Ein Tap am Tag reicht für klare Daten.")
                featureCard(icon: "chart.line.uptrend.xyaxis", title: "Muster erkennen", subtitle: "Sieh sofort, was wirklich funktioniert.")
                featureCard(icon: "target", title: "Fokus halten", subtitle: "Weniger Gewohnheiten, mehr Wirkung.")
            }
        case .focus:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(FocusArea.allCases) { area in
                    selectionCard(
                        title: area.title,
                        subtitle: "Vorschläge für \(area.title.lowercased())",
                        selected: selectedFocusAreas.contains(area)
                    ) {
                        toggle(area)
                    }
                }
            }
            Text("Wähle mindestens einen Bereich.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
        case .groups:
            VStack(spacing: 12) {
                ForEach(OnboardingGroupPreset.allCases) { preset in
                    optionCard(
                        title: preset.title,
                        subtitle: preset.subtitle,
                        selected: selectedGroupPresets.contains(preset)
                    ) {
                        toggleGroupPreset(preset)
                    }
                }
            }
            Text("Diese Gruppen werden automatisch für dich angelegt.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
        case .weekStart:
            VStack(spacing: 12) {
                optionCard(title: "Montag", subtitle: "Ideal für Arbeitswochen", selected: weekStart == .monday) {
                    weekStart = .monday
                }
                optionCard(title: "Sonntag", subtitle: "Kalenderwoche klassisch", selected: weekStart == .sunday) {
                    weekStart = .sunday
                }
            }
        case .tracking:
            VStack(spacing: 12) {
                optionCard(
                    title: HabitTrackingType.binary.title,
                    subtitle: "Abhaken reicht",
                    selected: preferredTrackingType == .binary
                ) {
                    preferredTrackingType = .binary
                }

                optionCard(
                    title: HabitTrackingType.count.title,
                    subtitle: "Für Wasser, Schritte, Wiederholungen",
                    selected: preferredTrackingType == .count
                ) {
                    preferredTrackingType = .count
                }
            }
        case .reminders:
            VStack(spacing: 12) {
                optionCard(title: "Ja, Erinnerungen aktivieren", subtitle: "Hilft beim Dranbleiben", selected: requestReminders) {
                    requestReminders = true
                }
                optionCard(title: "Nein, erstmal ohne", subtitle: "Du kannst es später in Settings aktivieren", selected: !requestReminders) {
                    requestReminders = false
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.15)
            Button {
                nextAction()
            } label: {
                Text(step == .reminders ? "Loslegen" : "Weiter")
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isNextDisabled)
            .padding(24)
        }
    }

    private func featureCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func selectionCard(title: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                }
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.accentColor : Color.primary.opacity(0.05), lineWidth: selected ? 1.2 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func optionCard(title: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                    .font(.system(size: 20, weight: .semibold))
            }
            .padding(16)
            .background(selected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? Color.accentColor : Color.primary.opacity(0.05), lineWidth: selected ? 1.2 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var isNextDisabled: Bool {
        step == .focus && selectedFocusAreas.isEmpty
    }

    private func nextAction() {
        if step == .reminders {
            onContinue(
                OnboardingSelection(
                    weekStart: weekStart,
                    focusAreas: Array(selectedFocusAreas).sorted { $0.rawValue < $1.rawValue },
                    groupPresets: Array(selectedGroupPresets).sorted { $0.rawValue < $1.rawValue },
                    preferredTrackingType: preferredTrackingType,
                    requestReminders: requestReminders
                )
            )
            return
        }
        guard let next = step.next else { return }
        step = next
    }

    private func goBack() {
        guard let previous = step.previous else { return }
        step = previous
    }

    private func toggle(_ area: FocusArea) {
        if selectedFocusAreas.contains(area) {
            if selectedFocusAreas.count > 1 {
                selectedFocusAreas.remove(area)
            }
        } else {
            selectedFocusAreas.insert(area)
        }
    }

    private func toggleGroupPreset(_ preset: OnboardingGroupPreset) {
        if selectedGroupPresets.contains(preset) {
            if selectedGroupPresets.count > 1 {
                selectedGroupPresets.remove(preset)
            }
        } else {
            selectedGroupPresets.insert(preset)
        }
    }
}

#Preview {
    OnboardingView(initialWeekStart: .monday, initialFocusAreas: [.health, .learning]) { _ in }
}

private enum OnboardingStep: Int, CaseIterable {
    case intro
    case focus
    case groups
    case weekStart
    case tracking
    case reminders

    var index: Int { rawValue }

    var title: String {
        switch self {
        case .intro:
            return "Willkommen bei DoneDaily"
        case .focus:
            return "Worauf willst du dich fokussieren?"
        case .groups:
            return "Wie willst du strukturieren?"
        case .weekStart:
            return "Wie soll deine Woche starten?"
        case .tracking:
            return "Wie willst du Habits abhaken?"
        case .reminders:
            return "Willst du Erinnerungen?"
        }
    }

    var subtitle: String {
        switch self {
        case .intro:
            return "Ein kurzer Setup-Flow, dann bekommst du passende Habit-Vorschläge."
        case .focus:
            return "Wir verwenden das nur für deine Vorschläge."
        case .groups:
            return "Gruppen halten deine Habits übersichtlich."
        case .weekStart:
            return "Das beeinflusst Auswertungen und Wochenfortschritt."
        case .tracking:
            return "Du kannst das pro Habit später jederzeit ändern."
        case .reminders:
            return "Du kannst das jederzeit in den Einstellungen ändern."
        }
    }

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }
}

enum OnboardingGroupPreset: String, CaseIterable, Identifiable {
    case health
    case focus
    case lifestyle
    case routine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health:
            return "Gesundheit"
        case .focus:
            return "Fokus & Produktivität"
        case .lifestyle:
            return "Alltag"
        case .routine:
            return "Morgen/Abend Routine"
        }
    }

    var subtitle: String {
        switch self {
        case .health:
            return "Trinken, Schlaf, Bewegung"
        case .focus:
            return "Deep Work, Planung, Prioritäten"
        case .lifestyle:
            return "Organisation und Haushalt"
        case .routine:
            return "Anker für Tagesstart und -ende"
        }
    }
}
