import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var settings: AppSettings

    @State private var notificationStatusText = "Nicht gepruft"
    @State private var exportCSVURL: URL?
    @State private var exportJSONURL: URL?
    @State private var exportStatus = ""
    @State private var isImportPickerPresented = false
    @State private var showDevelopmentResetAlert = false
    @State private var developmentResetStatus = ""

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    groupCard {
                        Toggle("Dark Mode", isOn: darkModeBinding)

                        Picker("Darstellung", selection: $settings.appearance) {
                            ForEach(AppAppearance.allCases) { value in
                                Text(value.title).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("iCloud Sync", isOn: $settings.iCloudSyncEnabled)

                        Picker("Wochenstart", selection: $settings.weekStart) {
                            ForEach(WeekStart.allCases) { value in
                                Text(value.title).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    groupCard {
                        Button("Berechtigung anfragen") {
                            requestNotifications()
                        }
                        .foregroundStyle(primaryText)

                        Button("iOS Einstellungen offnen") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                        .foregroundStyle(primaryText)

                        Button("Reminder neu synchronisieren") {
                            ReminderSyncService.syncAll(context: modelContext)
                        }
                        .foregroundStyle(primaryText)

                        Text("Status: \(notificationStatusText)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(secondaryText)
                    }

                    groupCard {
                        Button("Daten Export") {
                            performExport()
                        }
                        .foregroundStyle(primaryText)

                        Button("JSON importieren") {
                            isImportPickerPresented = true
                        }
                        .foregroundStyle(primaryText)

                        if let exportCSVURL {
                            ShareLink(item: exportCSVURL) {
                                Text("CSV teilen")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(accent)
                        }

                        if let exportJSONURL {
                            ShareLink(item: exportJSONURL) {
                                Text("JSON teilen")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        if !exportStatus.isEmpty {
                            Text(exportStatus)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(secondaryText)
                        }
                    }

#if DEBUG
                    groupCard {
                        Text("Entwicklung")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(primaryText)

                        Button {
                            seedInsightsTestData()
                        } label: {
                            Text("Insights-Testdaten laden")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(role: .destructive) {
                            showDevelopmentResetAlert = true
                        } label: {
                            Text("App komplett zurucksetzen")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !developmentResetStatus.isEmpty {
                            Text(developmentResetStatus)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(secondaryText)
                        }
                    }
#endif
                }
                .padding(.horizontal, AppDesign.screenPadding)
                .padding(.vertical, 8)
                .padding(.bottom, 24)
            }
            .background(AppBackgroundView())
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.large)
            .tint(accent)
            .task {
                await refreshNotificationStatus()
            }
            .fileImporter(
                isPresented: $isImportPickerPresented,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Alles zurucksetzen?", isPresented: $showDevelopmentResetAlert) {
                Button("Abbrechen", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    performDevelopmentReset()
                }
            } message: {
                Text("Loscht alle Habits, Gruppen und setzt das Onboarding fur die Entwicklung zuruck.")
            }
        }
    }

    private func groupCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        AppCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                content()
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
        switch await HabitReminderScheduler.authorizationStatus() {
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

    private func performExport() {
        do {
            let files = try DataExportService.exportFiles(context: modelContext)
            exportCSVURL = files.csv
            exportJSONURL = files.json
            exportStatus = "Export erstellt: \(files.csv.lastPathComponent), \(files.json.lastPathComponent)"
        } catch {
            exportCSVURL = nil
            exportJSONURL = nil
            exportStatus = "Export fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            let secured = url.startAccessingSecurityScopedResource()
            defer {
                if secured { url.stopAccessingSecurityScopedResource() }
            }

            do {
                let imported = try DataExportService.importHabits(from: url, context: modelContext)
                exportStatus = "Import abgeschlossen: \(imported) Habits."
                ReminderSyncService.syncAll(context: modelContext)
                Haptics.success()
            } catch {
                exportStatus = "Import fehlgeschlagen: \(error.localizedDescription)"
            }
        case let .failure(error):
            exportStatus = "Import abgebrochen: \(error.localizedDescription)"
        }
    }

    private func performDevelopmentReset() {
        do {
            let habits = try modelContext.fetch(FetchDescriptor<Habit>())
            let groups = try modelContext.fetch(FetchDescriptor<HabitGroup>())

            for habit in habits {
                Task { await HabitReminderScheduler.cancel(for: habit) }
                modelContext.delete(habit)
            }

            for group in groups {
                modelContext.delete(group)
            }

            guard modelContext.saveIfNeeded() else {
                developmentResetStatus = "Reset fehlgeschlagen: Speichern nicht moglich."
                return
            }

            settings.resetForDevelopment()
            exportCSVURL = nil
            exportJSONURL = nil
            exportStatus = ""
            developmentResetStatus = "Reset abgeschlossen (Daten + Onboarding)."
            ReminderSyncService.syncAll(context: modelContext)
            Haptics.success()
        } catch {
            developmentResetStatus = "Reset fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func seedInsightsTestData() {
        do {
            let existingHabits = try modelContext.fetch(FetchDescriptor<Habit>())
            let existingGroups = try modelContext.fetch(FetchDescriptor<HabitGroup>())

            let demoHabits = existingHabits.filter { $0.name.hasPrefix("Demo ") }
            let demoGroups = existingGroups.filter { $0.name.hasPrefix("Demo ") }

            for habit in demoHabits {
                Task { await HabitReminderScheduler.cancel(for: habit) }
                modelContext.delete(habit)
            }

            for group in demoGroups {
                modelContext.delete(group)
            }

            let healthGroup = HabitGroup(name: "Demo Gesundheit", sortOrder: 900)
            let focusGroup = HabitGroup(name: "Demo Fokus", sortOrder: 901)
            let productivityGroup = HabitGroup(name: "Demo Produktiv", sortOrder: 902)

            modelContext.insert(healthGroup)
            modelContext.insert(focusGroup)
            modelContext.insert(productivityGroup)

            let habits: [Habit] = [
                Habit(
                    name: "Demo Wasser 2L",
                    iconName: "drop.fill",
                    color: .blue,
                    targetPerWeek: 7,
                    trackingType: .count,
                    dailyTarget: 8,
                    category: .health,
                    group: healthGroup
                ),
                Habit(
                    name: "Demo Workout",
                    iconName: "figure.run",
                    color: .green,
                    targetPerWeek: 4,
                    trackingType: .binary,
                    category: .fitness,
                    group: healthGroup
                ),
                Habit(
                    name: "Demo Fokus-Session",
                    iconName: "brain.head.profile",
                    color: .orange,
                    targetPerWeek: 6,
                    trackingType: .count,
                    dailyTarget: 3,
                    category: .productivity,
                    group: focusGroup
                ),
                Habit(
                    name: "Demo Lesen 20 Min",
                    iconName: "book.fill",
                    color: .pink,
                    targetPerWeek: 6,
                    trackingType: .binary,
                    category: .learning,
                    group: focusGroup
                ),
                Habit(
                    name: "Demo Inbox Zero",
                    iconName: "tray.full.fill",
                    color: .blue,
                    targetPerWeek: 5,
                    trackingType: .binary,
                    category: .productivity,
                    group: productivityGroup
                )
            ]

            for habit in habits {
                modelContext.insert(habit)
            }

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)

            for offset in 0..<90 {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
                let weekday = calendar.component(.weekday, from: day)

                if let water = habits.first(where: { $0.name == "Demo Wasser 2L" }) {
                    let weekdayBase = [1: 5, 2: 8, 3: 7, 4: 8, 5: 7, 6: 8, 7: 6][weekday] ?? 6
                    let dip = offset % 11 == 0 ? 3 : 0
                    let progress = max(0, min(8, weekdayBase - dip))
                    water.logs.append(HabitLog(date: day, completed: progress >= 8, progressCount: progress, habit: water))
                }

                if let workout = habits.first(where: { $0.name == "Demo Workout" }) {
                    let completed = (weekday == 2 || weekday == 4 || weekday == 6 || (offset % 10 == 0))
                    if completed {
                        workout.logs.append(HabitLog(date: day, completed: true, progressCount: 1, habit: workout))
                    }
                }

                if let focus = habits.first(where: { $0.name == "Demo Fokus-Session" }) {
                    let weekdayBase = [1: 1, 2: 3, 3: 2, 4: 3, 5: 2, 6: 3, 7: 1][weekday] ?? 2
                    let dip = offset % 14 == 0 ? 1 : 0
                    let progress = max(0, min(3, weekdayBase - dip))
                    focus.logs.append(HabitLog(date: day, completed: progress >= 3, progressCount: progress, habit: focus))
                }

                if let reading = habits.first(where: { $0.name == "Demo Lesen 20 Min" }) {
                    let completed = weekday != 1 && offset % 8 != 0
                    if completed {
                        reading.logs.append(HabitLog(date: day, completed: true, progressCount: 1, habit: reading))
                    }
                }

                if let inbox = habits.first(where: { $0.name == "Demo Inbox Zero" }) {
                    let completed = weekday != 7 && weekday != 1 && offset % 9 != 0
                    if completed {
                        inbox.logs.append(HabitLog(date: day, completed: true, progressCount: 1, habit: inbox))
                    }
                }
            }

            guard modelContext.saveIfNeeded() else {
                developmentResetStatus = "Testdaten konnten nicht gespeichert werden."
                return
            }

            developmentResetStatus = "Insights-Testdaten geladen (90 Tage, 5 Demo-Habits)."
            ReminderSyncService.syncAll(context: modelContext)
            Haptics.success()
        } catch {
            developmentResetStatus = "Testdaten fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private var darkModeBinding: Binding<Bool> {
        Binding(
            get: { settings.appearance == .dark },
            set: { settings.appearance = $0 ? .dark : .light }
        )
    }

    private var appBackground: Color {
        colorScheme == .dark ? .appBackgroundDark : .appBackgroundLight
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
    SettingsView()
        .environmentObject(AppSettings())
        .modelContainer(PreviewData.container)
}
