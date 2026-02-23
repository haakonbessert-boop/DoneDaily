import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Group {
            if settings.onboardingCompleted {
                TabView {
                    TodayView()
                        .tabItem {
                            Label("Heute", systemImage: "checkmark.circle")
                        }

                    HabitsView()
                        .tabItem {
                            Label("Habits", systemImage: "list.bullet")
                        }

                    StatsView()
                        .tabItem {
                            Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                        }

                    SettingsView()
                        .tabItem {
                            Label("Einstellungen", systemImage: "gearshape")
                        }
                }
                .tint(colorScheme == .dark ? .appAccentDark : .appAccentLight)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .tabBar)
                .onAppear {
                    AppPerformanceMonitor.markFirstRender()
                }
            } else {
                OnboardingView(
                    initialWeekStart: settings.weekStart,
                    initialFocusAreas: settings.focusAreas
                ) { selection in
                    settings.weekStart = selection.weekStart
                    settings.focusAreas = selection.focusAreas
                    settings.preferredTrackingType = selection.preferredTrackingType
                    seedOnboardingGroups(selection.groupPresets)
                    settings.onboardingCompleted = true
                    if selection.requestReminders {
                        Task {
                            _ = try? await HabitReminderScheduler.requestAuthorization()
                        }
                    }
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: settings.onboardingCompleted)
        .preferredColorScheme(settings.appearance.colorScheme)
    }

    private func seedOnboardingGroups(_ presets: [OnboardingGroupPreset]) {
        guard !presets.isEmpty else { return }
        let descriptor = FetchDescriptor<HabitGroup>(sortBy: [SortDescriptor(\HabitGroup.sortOrder), SortDescriptor(\HabitGroup.createdAt)])
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for (index, preset) in presets.enumerated() {
            modelContext.insert(HabitGroup(name: preset.title, sortOrder: index))
        }
        _ = modelContext.saveIfNeeded()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
        .modelContainer(PreviewData.container)
}
