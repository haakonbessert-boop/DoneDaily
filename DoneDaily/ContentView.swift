import SwiftUI

struct ContentView: View {
    var body: some View {
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
        }
    }
}

#Preview {
    ContentView()
}
