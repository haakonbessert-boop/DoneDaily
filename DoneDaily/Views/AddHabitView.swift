import SwiftData
import SwiftUI

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "checkmark.seal.fill"
    @State private var color: HabitColor = .blue
    @State private var target = 5

    private let suggestedIcons = [
        "checkmark.seal.fill",
        "book.fill",
        "figure.run",
        "drop.fill",
        "moon.fill",
        "brain.head.profile"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Basis") {
                    TextField("Name", text: $name)
                    Stepper("Ziel pro Woche: \(target)", value: $target, in: 1...7)
                }

                Section("Farbe") {
                    Picker("Farbe", selection: $color) {
                        ForEach(HabitColor.allCases) { item in
                            Text(item.rawValue.capitalized)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Icon") {
                    Picker("Icon", selection: $icon) {
                        ForEach(suggestedIcons, id: \.self) { symbol in
                            Label(symbol, systemImage: symbol)
                                .tag(symbol)
                        }
                    }
                }
            }
            .navigationTitle("Neuer Habit")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }

                        let habit = Habit(
                            name: trimmedName,
                            iconName: icon,
                            color: color,
                            targetPerWeek: target
                        )
                        modelContext.insert(habit)
                        modelContext.saveIfNeeded()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddHabitView()
        .modelContainer(PreviewData.container)
}
