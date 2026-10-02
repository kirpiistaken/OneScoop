import SwiftUI
import UIKit

struct HistoryView: View {
    @EnvironmentObject private var store: CreatineStore
    @EnvironmentObject private var plus: PlusStore
    @State private var showInsights = false
    @State private var showBadges = false
    @State private var showPaywall = false
    @State private var month = DayKey.startOfDay(Date())
    /// 2.0 — Takvimin altındaki küçük düğme: kreatin ya da su takvimi.
    @AppStorage("ct.history.showWater") private var showWaterPref = false
    @State private var waterDay: WaterDaySelection?

    private var showWater: Bool { showWaterPref && store.water.enabled }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        ZStack {
            CT.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    monthHeader
                    weekdayRow
                    if showWater {
                        waterGrid
                    } else {
                        grid
                    }
                    if store.water.enabled { modeSwitch }
                    badgesCard
                    weeklyCard
                    if showWater {
                        waterSummary
                    } else {
                        legend
                        summary
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .sheet(item: $waterDay) { WaterEntriesSheet(date: $0.date) }
        .sheet(isPresented: $showInsights) { ReportsView() }
        .sheet(isPresented: $showBadges) { BadgesView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Rozetler (2.1, ücretsiz)

    private var badgesCard: some View {
        let progress = store.badgeProgress
        let recent = Badge.all
            .filter { progress.isEarned($0) }
            .sorted { (progress.earned[$0.id] ?? .distantPast) > (progress.earned[$1.id] ?? .distantPast) }
            .prefix(3)
        return Button { showBadges = true } label: {
            HStack(spacing: 12) {
                if recent.isEmpty {
                    MedalView(badge: Badge.all[0], ribbon: Badge.all[0].ribbon, locked: true, width: 34, glows: false)
                } else {
                    HStack(spacing: -10) {
                        ForEach(Array(recent)) { b in
                            MedalView(badge: b, ribbon: progress.ribbon(for: b), width: 34, glows: false)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.badgesTitle)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(CT.ink)
                    Text(L.badgesEarned(progress.earnedCount, Badge.all.count))
                        .font(.caption)
                        .foregroundStyle(CT.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CT.inkSoft)
            }
            .padding(14)
            .background(CT.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: - Haftalık / aylık rapor (özet ücretsiz, grafikler OneScoop+)

    private var weeklyCard: some View {
        Button {
            showInsights = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CT.accent)
                    .frame(width: 36, height: 36)
                    .background(CT.accent.opacity(0.12), in: Circle())
                Text(L.reportsTitle)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(CT.ink)
                Spacer()
                if !plus.isUnlocked {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CT.gold)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CT.inkSoft)
            }
            .padding(14)
            .background(CT.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: - Kreatin / Su düğmesi

    private var modeSwitch: some View {
        Picker(selection: Binding(
            get: { showWater },
            set: { new in withAnimation(.snappy) { showWaterPref = new } }
        )) {
            Text(L.historyCreatine).tag(false)
            Text(L.waterTitle).tag(true)
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
        .controlSize(.small)
        .frame(width: 180)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Su takvimi

    /// Bu ekran store'daki su değişince yeniden çiziliyor; geçmiş günler
    /// (ve Sağlık'tan gelenler) doğrudan kayıttan okunuyor.
    private var waterLog: [String: [WaterEntry]] {
        _ = store.waterToday
        return WaterData.mergedLog()
    }

    private func waterTotal(_ day: Date, in log: [String: [WaterEntry]]) -> Int {
        (log[DayKey.key(for: day)] ?? []).reduce(0) { $0 + $1.ml }
    }

    private var waterGrid: some View {
        let log = waterLog
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                if let day {
                    let isFuture = DayKey.startOfDay(day) > DayKey.startOfDay(Date())
                    WaterDayCell(
                        date: day,
                        total: waterTotal(day, in: log),
                        goal: WaterData.goal(on: day),
                        isToday: DayKey.key(for: day) == DayKey.today,
                        isFuture: isFuture
                    )
                    .onTapGesture {
                        guard !isFuture else { return }
                        waterDay = WaterDaySelection(date: day)
                    }
                } else {
                    Color.clear.frame(height: 46)
                }
            }
        }
    }

    private var waterSummary: some View {
        let log = waterLog
        let days = monthDays.filter { DayKey.startOfDay($0) <= DayKey.startOfDay(Date()) }
        let totals = days.map { waterTotal($0, in: log) }
        let drankDays = totals.filter { $0 > 0 }
        let goalDays = zip(days, totals).filter { $1 >= WaterData.goal(on: $0) }.count
        let average = drankDays.isEmpty ? 0 : drankDays.reduce(0, +) / drankDays.count
        let monthTotal = totals.reduce(0, +)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                statBox(value: "\(goalDays)", label: L.historyWaterGoalDays)
                statBox(value: "\(average.litersString) L", label: L.historyWaterAverage)
                statBox(value: "\(monthTotal.litersString) L", label: L.historyThisMonth)
            }
            Text(L.historyWaterHint)
                .font(.caption)
                .foregroundStyle(CT.inkSoft.opacity(0.8))
        }
    }

    private var monthDays: [Date] { gridDays.compactMap { $0 } }

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
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(verbatim: symbol)
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
            legendItem(color: CT.accent, label: L.historyMaintenance)
            if store.settings.usesLoadingPhase {
                legendItem(color: CT.loading, label: L.historyLoading)
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
                statBox(value: "\(entries.count)", label: L.historyDaysLogged)
                statBox(value: "\(Stats.totalGrams(entries).gramString) g", label: L.historyThisMonth)
                statBox(value: "\(store.streak)", label: L.historyDayStreak)
            }

            Text(Stats.insight(for: month, log: store.log, settings: store.settings))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(CT.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CT.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(L.historyTapHint)
                .font(.caption)
                .foregroundStyle(CT.inkSoft.opacity(0.8))
        }
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(verbatim: value)
                .font(CT.display(22, .heavy))
                .foregroundStyle(CT.ink)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(CT.inkSoft)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
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

    /// Hafta günü harfleri cihaz dilinde ve cihazın hafta başlangıcına göre.
    private var weekdaySymbols: [String] {
        let symbols = DayKey.calendar.veryShortStandaloneWeekdaySymbols
        let first = DayKey.calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

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
            Text(verbatim: "\(DayKey.calendar.component(.day, from: date))")
                .font(.system(size: 15, weight: entry != nil ? .bold : .medium, design: .rounded))
                .foregroundStyle(entry != nil ? .white : (isFuture ? CT.inkSoft.opacity(0.4) : CT.ink))

            if let entry {
                Text(verbatim: entry.grams.gramString)
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

// MARK: - Su günü

struct WaterDaySelection: Identifiable {
    let date: Date
    var id: String { DayKey.key(for: date) }
}

/// Hedefe göre alttan dolan gün kutusu; hedefe ulaşılan gün tamamen dolu.
private struct WaterDayCell: View {
    let date: Date
    let total: Int
    let goal: Int
    let isToday: Bool
    let isFuture: Bool

    private var fraction: Double { goal > 0 ? min(1, Double(total) / Double(goal)) : 0 }
    private var reached: Bool { total >= goal && goal > 0 }

    var body: some View {
        VStack(spacing: 3) {
            Text(verbatim: "\(DayKey.calendar.component(.day, from: date))")
                .font(.system(size: 15, weight: total > 0 ? .bold : .medium, design: .rounded))
                .foregroundStyle(reached ? .white : (isFuture ? CT.inkSoft.opacity(0.4) : CT.ink))

            if total > 0 {
                Text(verbatim: total.litersString)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(reached ? .white.opacity(0.85) : CT.inkSoft)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background {
            let shape = RoundedRectangle(cornerRadius: 13, style: .continuous)
            ZStack(alignment: .bottom) {
                shape.fill(CT.surface)
                GeometryReader { geo in
                    Rectangle()
                        .fill(reached ? CT.accent : CT.accent.opacity(0.28))
                        .frame(height: geo.size.height * fraction)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .clipShape(shape)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(CT.accent, lineWidth: isToday && !reached ? 2 : 0)
        }
    }
}
