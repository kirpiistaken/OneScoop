import UIKit
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: CreatineStore
    @State private var month = DayKey.startOfDay(Date())

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        ZStack {
            CT.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    monthHeader
                    weekdayRow
                    grid
                    legend
                    summary
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Header

    private var monthHeader: some View {
        HStack {
            navButton("chevron.left") { shift(-1) }
            Spacer()
            Text(month, format: .dateTime.month(.wide).year())
                .font(CT.display(22, .bold))
                .foregroundStyle(CT.ink)
                .contentTransition(.numericText())
            Spacer()
            navButton("chevron.right") { shift(1) }
                .disabled(isCurrentMonth)
                .opacity(isCurrentMonth ? 0.25 : 1)
        }
        .padding(.top, 12)
    }

    private func navButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(CT.ink)
                .frame(width: 38, height: 38)
                .background(CT.surface, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var weekdayRow: some View {
        HStack(spacing: 6) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(CT.inkSoft)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Grid

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(
                        date: day,
                        entry: store.entry(for: day),
                        isLoadingDay: store.settings.isLoadingDay(day),
                        isToday: DayKey.key(for: day) == DayKey.today,
                        isFuture: DayKey.startOfDay(day) > DayKey.startOfDay(Date())
                    )
                    .onTapGesture { toggle(day) }
                } else {
                    Color.clear.frame(height: 46)
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 18) {
            legendItem(color: CT.accent, label: "Maintenance")
            if store.settings.usesLoadingPhase {
                legendItem(color: CT.loading, label: "Loading")
            }
            Spacer()
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(CT.inkSoft)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(label)
        }
    }

    // MARK: - Summary

    private var summary: some View {
        let entries = Stats.entries(in: month, log: store.log)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                statBox(value: "\(entries.count)", label: "days logged")
                statBox(value: "\(Stats.totalGrams(entries).gramString) g", label: "this month")
                statBox(value: "\(store.streak)", label: "day streak")
            }

            Text(Stats.insight(for: month, log: store.log, settings: store.settings))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(CT.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CT.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text("Tap any past day to add or remove an entry.")
                .font(.caption)
                .foregroundStyle(CT.inkSoft.opacity(0.8))
        }
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(CT.display(22, .heavy))
                .foregroundStyle(CT.ink)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(CT.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Logic

    private var isCurrentMonth: Bool {
        DayKey.calendar.isDate(month, equalTo: Date(), toGranularity: .month)
    }

    private func shift(_ delta: Int) {
        guard let next = DayKey.calendar.date(byAdding: .month, value: delta, to: month) else { return }
        withAnimation(.snappy) { month = next }
    }

    private func toggle(_ day: Date) {
        guard DayKey.startOfDay(day) <= DayKey.startOfDay(Date()) else { return }
        withAnimation(.snappy) {
            if store.entry(for: day) != nil {
                store.undo(on: day)
            } else {
                store.markTaken(on: day)
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var weekdaySymbols: [String] {
        let symbols = DayKey.calendar.veryShortStandaloneWeekdaySymbols
        let first = DayKey.calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Ayın günleri + baştaki boşluklar.
    private var gridDays: [Date?] {
        guard let interval = DayKey.calendar.dateInterval(of: .month, for: month),
              let range = DayKey.calendar.range(of: .day, in: .month, for: month) else { return [] }

        let weekday = DayKey.calendar.component(.weekday, from: interval.start)
        let leading = (weekday - DayKey.calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<range.count {
            days.append(DayKey.calendar.date(byAdding: .day, value: offset, to: interval.start))
        }
        return days
    }
}

// MARK: - Day cell

private struct DayCell: View {
    let date: Date
    let entry: DoseEntry?
    let isLoadingDay: Bool
    let isToday: Bool
    let isFuture: Bool

    private var fill: Color {
        guard entry != nil else { return .clear }
        return isLoadingDay ? CT.loading : CT.accent
    }

    var body: some View {
        VStack(spacing: 3) {
            Text("\(DayKey.calendar.component(.day, from: date))")
                .font(.system(size: 15, weight: entry != nil ? .bold : .medium, design: .rounded))
                .foregroundStyle(entry != nil ? .white : (isFuture ? CT.inkSoft.opacity(0.4) : CT.ink))

            if let entry {
                Text(entry.grams.gramString)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(entry != nil ? fill : CT.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(CT.accent, lineWidth: isToday && entry == nil ? 2 : 0)
        }
    }
}
