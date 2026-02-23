import SwiftData
import SwiftUI

@main
struct DoneDailyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appSettings = AppSettings()
    private let container: ModelContainer

    init() {
        AppPerformanceMonitor.markLaunchStart()
        let schema = Schema([HabitGroup.self, Habit.self, HabitLog.self])

        do {
            container = try Self.makeContainer(schema: schema, isStoredInMemoryOnly: false)
        } catch {
            AppErrorReporter.report("Failed to initialize persistent SwiftData container: \(error)")
            do {
                try Self.deleteDefaultStoreFiles()
                container = try Self.makeContainer(schema: schema, isStoredInMemoryOnly: false)
                AppErrorReporter.report("Recovered by resetting incompatible SwiftData store.")
            } catch {
                AppErrorReporter.report("Persistent recovery failed: \(error)")
                do {
                    container = try Self.makeContainer(schema: schema, isStoredInMemoryOnly: true)
                    AppErrorReporter.report("Running with in-memory SwiftData container as fallback.")
                } catch {
                    fatalError("Failed to initialize SwiftData container: \(error)")
                }
            }
        }

        ReminderSyncService.syncAll(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            ReminderSyncService.syncAll(context: container.mainContext)
        }
    }

    private static func makeContainer(schema: Schema, isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func deleteDefaultStoreFiles() throws {
        let fileManager = FileManager.default
        guard let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        try SwiftDataStoreRecovery.deleteLikelyStoreFiles(in: appSupportDirectory)
    }
}
