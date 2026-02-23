import XCTest
@testable import DoneDaily

@MainActor
final class AppSettingsTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "settings.weekStart")
        defaults.removeObject(forKey: "settings.onboardingCompleted")
        defaults.removeObject(forKey: "settings.appearance")
        defaults.removeObject(forKey: "settings.icloudSyncEnabled")
        defaults.removeObject(forKey: "settings.focusAreas")
        defaults.removeObject(forKey: "settings.preferredTrackingType")
        return defaults
    }

    func testWeekStartPersistsToDefaults() {
        let defaults = makeDefaults()

        let settings = AppSettings(defaults: defaults, launchArguments: [])
        settings.weekStart = .sunday

        XCTAssertEqual(defaults.integer(forKey: "settings.weekStart"), WeekStart.sunday.rawValue)
    }

    func testOnboardingPersistsToDefaults() {
        let defaults = makeDefaults()

        let settings = AppSettings(defaults: defaults, launchArguments: [])
        settings.onboardingCompleted = true

        XCTAssertTrue(defaults.bool(forKey: "settings.onboardingCompleted"))
    }

    func testAppearancePersistsToDefaults() {
        let defaults = makeDefaults()

        let settings = AppSettings(defaults: defaults, launchArguments: [])
        settings.appearance = .dark

        XCTAssertEqual(defaults.string(forKey: "settings.appearance"), AppAppearance.dark.rawValue)
    }

    func testICloudSyncPersistsToDefaults() {
        let defaults = makeDefaults()

        let settings = AppSettings(defaults: defaults, launchArguments: [])
        settings.iCloudSyncEnabled = true

        XCTAssertTrue(defaults.bool(forKey: "settings.icloudSyncEnabled"))
    }

    func testFocusAreasPersistToDefaults() {
        let defaults = makeDefaults()

        let settings = AppSettings(defaults: defaults, launchArguments: [])
        settings.focusAreas = [.sleep, .fitness]

        XCTAssertEqual(defaults.string(forKey: "settings.focusAreas"), "sleep,fitness")
    }

    func testResetForDevelopmentRestoresDefaults() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults, launchArguments: [])

        settings.weekStart = .sunday
        settings.onboardingCompleted = true
        settings.appearance = .dark
        settings.iCloudSyncEnabled = true
        settings.focusAreas = [.adhd]

        settings.resetForDevelopment()

        XCTAssertEqual(settings.weekStart, .monday)
        XCTAssertFalse(settings.onboardingCompleted)
        XCTAssertEqual(settings.appearance, .system)
        XCTAssertFalse(settings.iCloudSyncEnabled)
        XCTAssertEqual(settings.focusAreas, [.health, .learning])
        XCTAssertEqual(settings.preferredTrackingType, .binary)
    }
}
