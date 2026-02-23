import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var notificationStatusText = "Nicht geprüft"

    var body: some View {
        NavigationStack {
            Form {
                Section("Woche") {
                    Picker("Wochenstart", selection: $settings.weekStart) {
                        ForEach(WeekStart.allCases) { value in
                            Text(value.title).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Benachrichtigungen") {
                    Text("Reminder werden nur lokal auf deinem Gerät verarbeitet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Berechtigung anfragen") {
                        requestNotifications()
                    }
                    Text(notificationStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Einstellungen")
            .task {
                await refreshNotificationStatus()
            }
        }
    }

    private func requestNotifications() {
        Task {
            _ = try? await HabitReminderScheduler.requestAuthorization()
            await refreshNotificationStatus()
        }
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            notificationStatusText = "Aktiv"
        case .denied:
            notificationStatusText = "Abgelehnt"
        case .notDetermined:
            notificationStatusText = "Nicht festgelegt"
        @unknown default:
            notificationStatusText = "Unbekannt"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
}
