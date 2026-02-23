import SwiftUI

struct WeekdayPickerView: View {
    @Binding var selectedWeekdays: Set<Int>

    private let labels = Calendar.current.shortWeekdaySymbols

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 30)), count: 7), spacing: 8) {
            ForEach(Array(1...7), id: \.self) { weekday in
                Button {
                    toggle(weekday)
                } label: {
                    Text(labels[weekday - 1])
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedWeekdays.contains(weekday) ? Color.accentColor : Color(.systemGray6))
                        .foregroundStyle(selectedWeekdays.contains(weekday) ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ weekday: Int) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }
}

#Preview {
    WeekdayPickerView(selectedWeekdays: .constant([2, 3, 4, 5, 6]))
        .padding()
}
