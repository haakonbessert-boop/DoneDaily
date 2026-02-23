import Charts
import SwiftUI

struct InsightsPeriodControl: View {
    @Binding var period: InsightPeriod

    var body: some View {
        HStack(spacing: 6) {
            ForEach(InsightPeriod.allCases) { value in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        period = value
                    }
                } label: {
                    Text(value.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(period == value ? Color.white : Color.primary.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(period == value ? Color.accentColor : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
        )
    }
}

struct InsightsComparisonCard: View {
    let current: Double
    let previous: Double
    let primaryText: Color

    private var delta: Double {
        current - previous
    }

    private var deltaPoints: Double {
        delta * 100
    }

    private var deltaPointsLabel: String {
        "\(deltaPoints >= 0 ? "+" : "")\(Int(deltaPoints.rounded())) pp"
    }

    private var relativeDeltaPercent: Double {
        guard previous > 0 else { return current > 0 ? 100 : 0 }
        return (delta / previous) * 100
    }

    private var relativeDeltaLabel: String {
        "\(relativeDeltaPercent >= 0 ? "+" : "")\(Int(relativeDeltaPercent.rounded()))%"
    }

    private var interpretationText: String {
        let points = Int(abs(deltaPoints).rounded())
        if points < 1 {
            return "Nahezu identisch zur Vorperiode."
        }
        if deltaPoints > 0 {
            return "\(points) Prozentpunkte besser als zuvor."
        }
        return "\(points) Prozentpunkte unter der Vorperiode."
    }

    private var deltaScaleRatio: Double {
        let clamped = max(-40, min(40, deltaPoints))
        return abs(clamped) / 40
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Vergleich zur Vorperiode")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(primaryText)

                HStack(spacing: 10) {
                    comparisonMetric(
                        title: "Aktuell",
                        value: current,
                        tint: .accentColor
                    )
                    comparisonMetric(
                        title: "Vorperiode",
                        value: previous,
                        tint: .secondary
                    )
                }

                HStack(spacing: 8) {
                    Text(deltaPointsLabel)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(delta >= 0 ? .green : .red)
                    Text("(\(relativeDeltaLabel))")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Text(interpretationText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                deltaScaleBar
                    .frame(height: 8)
            }
        }
    }

    private func comparisonMetric(title: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text("\(Int((value * 100).rounded()))%")
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(primaryText)
            GeometryReader { proxy in
                Capsule()
                    .fill(tint.opacity(0.2))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(tint)
                            .frame(width: proxy.size.width * max(0, min(1, value)))
                    }
            }
            .frame(height: 6)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var deltaScaleBar: some View {
        GeometryReader { proxy in
            let full = proxy.size.width
            let half = full / 2
            let fill = half * deltaScaleRatio

            ZStack {
                Capsule()
                    .fill(Color.secondary.opacity(0.16))

                Rectangle()
                    .fill(primaryText.opacity(0.22))
                    .frame(width: 1)

                HStack(spacing: 0) {
                    if delta >= 0 {
                        Spacer(minLength: half)
                        Capsule()
                            .fill(Color.green)
                            .frame(width: fill)
                        Spacer(minLength: max(0, half - fill))
                    } else {
                        Spacer(minLength: max(0, half - fill))
                        Capsule()
                            .fill(Color.red)
                            .frame(width: fill)
                        Spacer(minLength: half)
                    }
                }
            }
        }
    }
}

struct InsightsTrendCard: View {
    let series: [CompletionRatePoint]
    let primaryText: Color
    let secondaryText: Color
    let accent: Color
    @State private var selectedPoint: CompletionRatePoint?

    private var latestPoint: CompletionRatePoint? {
        series.last
    }

    private var firstPoint: CompletionRatePoint? {
        series.first
    }

    private var displayPoint: CompletionRatePoint? {
        selectedPoint ?? latestPoint
    }

    private var displayRate: Double {
        displayPoint?.rate ?? 0
    }

    private var deltaRate: Double {
        guard let current = displayPoint else { return 0 }
        if let selectedPoint {
            guard let index = series.firstIndex(where: { $0.id == selectedPoint.id }), index > 0 else { return 0 }
            return current.rate - series[index - 1].rate
        }
        return current.rate - (firstPoint?.rate ?? 0)
    }

    private var displayDateText: String {
        guard let date = displayPoint?.date else { return "" }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                InsightsSectionTitle(title: "Erfüllungs-Trend", primaryText: primaryText)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int((displayRate * 100).rounded()))%")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(primaryText.opacity(0.92))
                        .contentTransition(.numericText())
                    HStack(spacing: 8) {
                        Text("\(deltaRate >= 0 ? "+" : "")\(Int((deltaRate * 100).rounded()))%")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle((deltaRate >= 0 ? Color.green : Color.red).opacity(0.9))
                            .contentTransition(.numericText())
                        Text(displayDateText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(secondaryText)
                    }
                }

                Chart(series) { point in
                    AreaMark(
                        x: .value("Tag", point.date),
                        y: .value("Rate", point.rate)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accent.opacity(0.3), accent.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Tag", point.date),
                        y: .value("Rate", point.rate)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(accent)

                    if let selectedPoint {
                        RuleMark(x: .value("Auswahl", selectedPoint.date))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .foregroundStyle(secondaryText.opacity(0.7))
                        PointMark(
                            x: .value("Auswahl", selectedPoint.date),
                            y: .value("Rate", selectedPoint.rate)
                        )
                        .symbolSize(55)
                        .foregroundStyle(accent)
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks { _ in }
                }
                .chartXAxis {
                    AxisMarks(values: [series.first?.date, series.last?.date].compactMap { $0 }) { value in
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.day().month(.abbreviated)))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(secondaryText)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let frame = geometry[proxy.plotAreaFrame]
                                        let xPosition = value.location.x - frame.origin.x
                                        guard xPosition >= 0, xPosition <= frame.width else { return }
                                        guard let date: Date = proxy.value(atX: xPosition) else { return }
                                        selectedPoint = nearestPoint(to: date)
                                    }
                                    .onEnded { _ in
                                        selectedPoint = nil
                                    }
                            )
                    }
                }
                .frame(height: 240)
            }
        }
    }

    private func nearestPoint(to date: Date) -> CompletionRatePoint? {
        series.min(by: { lhs, rhs in
            abs(lhs.date.timeIntervalSince(date)) < abs(rhs.date.timeIntervalSince(date))
        })
    }
}

struct InsightsWeekdayCard: View {
    let bars: [WeekdayBarPoint]
    let primaryText: Color
    let secondaryText: Color
    let accent: Color
    let weekdayLabel: (Int) -> String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                InsightsSectionTitle(title: "Wochentage", primaryText: primaryText)

                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(bars) { bar in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(accent)
                                .frame(width: 10, height: max(6, 100 * bar.value))
                            Text(weekdayLabel(bar.weekday))
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(secondaryText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 140, alignment: .bottom)
            }
        }
    }
}

struct InsightsHeatmapCard: View {
    let cells: [HeatmapCell]
    let primaryText: Color
    let accent: Color

    private let calendar = Calendar.current

    private var monthStart: Date {
        let now = Date.now
        let components = calendar.dateComponents([.year, .month], from: now)
        return calendar.date(from: components) ?? now
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }

    private var firstWeekdayOffset: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday + 5) % 7
    }

    private var monthLabel: String {
        monthStart.formatted(.dateTime.month(.wide).year())
    }

    private var intensityByDay: [Date: Double] {
        Dictionary(uniqueKeysWithValues: cells.map { (calendar.startOfDay(for: $0.date), $0.intensity) })
    }

    private var weekdayLabels: [String] {
        ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                InsightsSectionTitle(title: "Monats-Heatmap", primaryText: primaryText)
                Text(monthLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(weekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.clear)
                            .frame(height: 30)
                    }

                    ForEach(1...daysInMonth, id: \.self) { day in
                        let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
                        let intensity = intensityByDay[calendar.startOfDay(for: date)] ?? 0
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(accent.opacity(max(0.08, intensity)))
                            .frame(height: 30)
                            .overlay {
                                Text("\(day)")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(primaryText.opacity(intensity > 0.45 ? 1 : 0.72))
                            }
                    }
                }
            }
        }
    }
}

struct InsightsDrilldownCard: View {
    let rows: [HabitDeviation]
    let primaryText: Color
    let secondaryText: Color
    let onSelect: (Habit) -> Void

    private var groupedRows: [(name: String, rows: [HabitDeviation])] {
        let grouped = Dictionary(grouping: rows) { row in
            row.habit.group?.name ?? "Ohne Gruppe"
        }
        return grouped
            .map { (name: $0.key, rows: $0.value.sorted { $0.completionRate > $1.completionRate }) }
            .sorted { lhs, rhs in
                if lhs.name == "Ohne Gruppe" { return false }
                if rhs.name == "Ohne Gruppe" { return true }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                InsightsSectionTitle(title: "Habit-Details", primaryText: primaryText)

                if rows.isEmpty {
                    Text("Noch keine Daten für Habit-Details.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(secondaryText)
                } else {
                    ForEach(groupedRows, id: \.name) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)

                            ForEach(section.rows) { row in
                                Button {
                                    onSelect(row.habit)
                                } label: {
                                    HStack {
                                        Text(row.habit.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(primaryText)
                                        Spacer()
                                        Text("\(Int((row.completionRate * 100).rounded()))%")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(primaryText)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct InsightsSectionTitle: View {
    let title: String
    let primaryText: Color

    var body: some View {
        Text(title)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(primaryText)
    }
}
