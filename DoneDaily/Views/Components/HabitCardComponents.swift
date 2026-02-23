import SwiftUI

struct MiniProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat

    init(progress: Double, lineWidth: CGFloat = 4, size: CGFloat = 40) {
        self.progress = max(0, min(1, progress))
        self.lineWidth = lineWidth
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Wochenfortschritt")
        .accessibilityValue("\(Int((progress * 100).rounded())) Prozent")
    }
}

struct WeekDotsView: View {
    let completed: Int
    let target: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .fill(index < min(completed, target) ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Wochentage erledigt")
        .accessibilityValue("\(min(completed, target)) von \(target)")
    }
}

struct LargeProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat

    init(progress: Double, size: CGFloat = 140, lineWidth: CGFloat = 12) {
        self.progress = max(0, min(1, progress))
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fokusfortschritt")
        .accessibilityValue("\(Int((progress * 100).rounded())) Prozent")
    }
}
