import Combine
import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    @Published var weekStart: WeekStart {
        didSet { defaults.set(weekStart.rawValue, forKey: Keys.weekStart) }
    }

    @Published var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: Keys.onboardingCompleted) }
    }

    @Published var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    @Published var iCloudSyncEnabled: Bool {
        didSet { defaults.set(iCloudSyncEnabled, forKey: Keys.iCloudSyncEnabled) }
    }

    @Published var focusAreas: [FocusArea] {
        didSet {
            let raw = focusAreas.map(\.rawValue).joined(separator: ",")
            defaults.set(raw, forKey: Keys.focusAreas)
        }
    }

    @Published var preferredTrackingType: HabitTrackingType {
        didSet { defaults.set(preferredTrackingType.rawValue, forKey: Keys.preferredTrackingType) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, launchArguments: [String] = ProcessInfo.processInfo.arguments) {
        self.defaults = defaults
        let storedWeekStart = defaults.integer(forKey: Keys.weekStart)
        let onboardingCompletedFromDefaults = defaults.bool(forKey: Keys.onboardingCompleted)
        let storedAppearance = defaults.string(forKey: Keys.appearance) ?? AppAppearance.system.rawValue
        self.weekStart = WeekStart(rawValue: storedWeekStart) ?? .monday
        self.onboardingCompleted = onboardingCompletedFromDefaults
        self.appearance = AppAppearance(rawValue: storedAppearance) ?? .system
        self.iCloudSyncEnabled = defaults.object(forKey: Keys.iCloudSyncEnabled) as? Bool ?? false
        self.focusAreas = AppSettings.decodeFocusAreas(defaults.string(forKey: Keys.focusAreas))
        self.preferredTrackingType = HabitTrackingType(rawValue: defaults.string(forKey: Keys.preferredTrackingType) ?? "") ?? .binary

        if launchArguments.contains("-uitest_reset_defaults") {
            defaults.removeObject(forKey: Keys.onboardingCompleted)
            defaults.removeObject(forKey: Keys.focusAreas)
            self.onboardingCompleted = false
            self.focusAreas = [.health, .learning]
            self.preferredTrackingType = .binary
        }
        if launchArguments.contains("-uitest_skip_onboarding") {
            self.onboardingCompleted = true
        }
    }

    func resetForDevelopment() {
        weekStart = .monday
        onboardingCompleted = false
        appearance = .system
        iCloudSyncEnabled = false
        focusAreas = [.health, .learning]
        preferredTrackingType = .binary
    }
}

private extension AppSettings {
    static func decodeFocusAreas(_ raw: String?) -> [FocusArea] {
        guard let raw else { return [.health, .learning] }
        let values = raw
            .split(separator: ",")
            .compactMap { FocusArea(rawValue: String($0)) }
        return values.isEmpty ? [.health, .learning] : values
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum WeekStart: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sunday:
            return "Sonntag"
        case .monday:
            return "Montag"
        }
    }
}

enum FocusArea: String, CaseIterable, Identifiable {
    case health
    case fitness
    case learning
    case mindfulness
    case productivity
    case adhd
    case sleep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health:
            return "Gesundheit"
        case .fitness:
            return "Fitness"
        case .learning:
            return "Lernen"
        case .mindfulness:
            return "Achtsamkeit"
        case .productivity:
            return "Produktivität"
        case .adhd:
            return "ADHS-Fokus"
        case .sleep:
            return "Schlaf"
        }
    }
}

private enum Keys {
    static let weekStart = "settings.weekStart"
    static let onboardingCompleted = "settings.onboardingCompleted"
    static let appearance = "settings.appearance"
    static let iCloudSyncEnabled = "settings.icloudSyncEnabled"
    static let focusAreas = "settings.focusAreas"
    static let preferredTrackingType = "settings.preferredTrackingType"
}
