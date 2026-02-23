import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    @Published var weekStart: WeekStart {
        didSet { defaults.set(weekStart.rawValue, forKey: Keys.weekStart) }
    }

    @Published var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: Keys.onboardingCompleted) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedWeekStart = defaults.integer(forKey: Keys.weekStart)
        self.weekStart = WeekStart(rawValue: storedWeekStart) ?? .monday
        self.onboardingCompleted = defaults.bool(forKey: Keys.onboardingCompleted)
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

private enum Keys {
    static let weekStart = "settings.weekStart"
    static let onboardingCompleted = "settings.onboardingCompleted"
}
