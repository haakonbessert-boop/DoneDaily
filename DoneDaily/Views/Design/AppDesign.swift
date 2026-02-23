import SwiftUI

enum AppDesign {
    static let cornerRadiusCard: CGFloat = 20
    static let cornerRadiusLargeCard: CGFloat = 24
    static let screenPadding: CGFloat = 20
    static let stackSpacing: CGFloat = 24
}

extension Color {
    static let appBackgroundLight = Color(red: 244 / 255, green: 245 / 255, blue: 248 / 255)
    static let appBackgroundDark = Color(red: 17 / 255, green: 19 / 255, blue: 24 / 255)

    static let appCardLight = Color.white.opacity(0.84)
    static let appCardDark = Color.white.opacity(0.12)

    static let appPrimaryTextLight = Color(red: 18 / 255, green: 20 / 255, blue: 33 / 255)
    static let appPrimaryTextDark = Color.white
    static let appSecondaryTextLight = Color(red: 87 / 255, green: 89 / 255, blue: 109 / 255)
    static let appSecondaryTextDark = Color(red: 178 / 255, green: 190 / 255, blue: 202 / 255)

    static let appAccentLight = Color(red: 42 / 255, green: 122 / 255, blue: 255 / 255)
    static let appAccentDark = Color(red: 94 / 255, green: 174 / 255, blue: 255 / 255)
}

struct AppBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            baseBackground

            Circle()
                .fill(glowPrimary)
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .offset(x: -140, y: -320)

            Circle()
                .fill(glowSecondary)
                .frame(width: 260, height: 260)
                .blur(radius: 100)
                .offset(x: 150, y: 320)
        }
        .ignoresSafeArea()
    }

    private var baseBackground: Color {
        colorScheme == .dark ? .appBackgroundDark : .appBackgroundLight
    }

    private var glowPrimary: Color {
        colorScheme == .dark
            ? Color(red: 86 / 255, green: 113 / 255, blue: 148 / 255).opacity(0.10)
            : Color(red: 187 / 255, green: 209 / 255, blue: 230 / 255).opacity(0.18)
    }

    private var glowSecondary: Color {
        colorScheme == .dark
            ? Color(red: 66 / 255, green: 88 / 255, blue: 112 / 255).opacity(0.08)
            : Color(red: 214 / 255, green: 223 / 255, blue: 235 / 255).opacity(0.16)
    }
}

struct AppCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let content: Content

    init(padding: CGFloat = 16, cornerRadius: CGFloat = AppDesign.cornerRadiusCard, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        Color.white.opacity(colorScheme == .dark ? 0.14 : 0.8),
                        lineWidth: colorScheme == .dark ? 0.6 : 0.7
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        Color.black.opacity(colorScheme == .dark ? 0.12 : 0.04),
                        lineWidth: 0.4
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.08),
                radius: colorScheme == .dark ? 10 : 6,
                x: 0,
                y: colorScheme == .dark ? 6 : 3
            )
    }

    private var cardBackground: Color {
        colorScheme == .dark ? .appCardDark : .appCardLight
    }
}
