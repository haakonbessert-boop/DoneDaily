import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            Text("DoneDaily")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 16) {
                onboardingItem(icon: "checkmark.circle.fill", title: "Täglicher Check-in", subtitle: "Ein Tap pro Habit reicht.")
                onboardingItem(icon: "flame.fill", title: "Streaks behalten", subtitle: "Bleib mit kleinen Schritten konstant.")
                onboardingItem(icon: "chart.bar.fill", title: "Fortschritt sehen", subtitle: "7- und 30-Tage Trends direkt im Blick.")
            }

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Loslegen")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }

    private func onboardingItem(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView(onContinue: {})
}
