import SwiftUI

extension HabitColor {
    var swiftUIColor: Color {
        switch self {
        case .blue:
            .blue
        case .green:
            .green
        case .orange:
            .orange
        case .red:
            .red
        case .pink:
            .pink
        }
    }
}
