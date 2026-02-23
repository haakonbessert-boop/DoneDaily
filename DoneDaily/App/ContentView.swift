import SwiftUI

struct ContentView: View {
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
                            Label("Statistik", systemImage: "chart.bar")
                        }

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
            } else {
                OnboardingView {
                    settings.onboardingCompleted = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
        .modelContainer(PreviewData.container)
}
