import SwiftUI
import Charts

// 2.1 — Haftalık ve aylık rapor. Sadece uygulama target'ında.
// Özet (halkalar / kutucuklar) herkese açık; grafikler OneScoop+.
// Tasarım: design/2.1/Weekly.dc.html ve Monthly.dc.html
//
// Hepsi gerçek kayıtlardan hesaplanıyor. "Kas kreatin doygunluğu" bir
// tahmin modeli ve ekranda öyle yazıyor: alınan gün kalan farkın dozla
// orantılı bir kısmı kapanıyor (5 g ≈ %11, 20 g ≈ %44), alınmayan gün
// %2,5 düşüyor. Yükleme fazıyla ~1 haftada, 3–5 g ile ~4 haftada doluyor;
// bırakınca birkaç haftada iniyor. Literatürdeki genel seyre uygun.

enum ReportMath {
    static let cal = DayKey.calendar

    static func days(endingAt end: Date, count: Int) -> [Date] {
        let last = DayKey.startOfDay(end)
        return (0..<count).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: last) }
    }

    static func monthDays(_ month: Date) -> [Date] {
        guard let interval = cal.dateInterval(of: .month, for: month),
              let range = cal.range(of: .day, in: .month, for: month) else { return [] }
        return (0..<range.count).compactMap { cal.date(byAdding: .day, value: $0, to: interval.start) }
    }

    /// Tahmini doygunluk (0…1) — son `count` gün için; 120 gün öncesinden başlar.
    static func saturation(log: [String: DoseEntry], endingAt end: Date, count: Int) -> [(Date, Double)] {
        let all = days(endingAt: end, count: 120)
        var s = 0.0
        var out: [(Date, Double)] = []
        for d in all {
            if let e = log[DayKey.key(for: d)] {
                s += (1 - s) * min(0.45, e.grams / 45)
            } else {
                s *= 0.975
            }
            out.append((d, s))
        }
        return Array(out.suffix(count))
    }

    /// Bu dozla kesintisiz devam edilirse %95'e kaç günde ulaşılır.
    static func daysToFull(from s: Double, dose: Double) -> Int {
        guard s < 0.95, dose > 0 else { return 0 }
        var v = s, n = 0
        while v < 0.95 && n < 200 { v += (1 - v) * min(0.45, dose / 45); n += 1 }
        return n
    }

    static func waterTotal(_ day: Date, _ log: [String: [WaterEntry]]) -> Int {
        (log[DayKey.key(for: day)] ?? []).reduce(0) { $0 + $1.ml }
    }

    static func liters(_ ml: Int) -> String { ml.litersString }
    static func liters(_ ml: Double) -> String { Int(ml.rounded()).litersString }
}

// MARK: - Ekran

struct ReportsView: View {
    @EnvironmentObject private var store: CreatineStore
    @EnvironmentObject private var plus: PlusStore
    @Environment(\.dismiss) private var dismiss
    @State private var monthly = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Picker(selection: $monthly) {
                        Text(L.reportsWeek).tag(false)
                        Text(L.reportsMonth).tag(true)
                    } label: { EmptyView() }
                    .pickerStyle(.segmented)

                    if monthly {
                        MonthlyReport(locked: !plus.isUnlocked, unlock: { showPaywall = true })
                    } else {
                        WeeklyReport(locked: !plus.isUnlocked, unlock: { showPaywall = true })
                    }
                }
                .padding(18)
            }
            .background(CT.bg.ignoresSafeArea())
            .navigationTitle(L.reportsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.commonDone) { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}

// MARK: - Ortak parçalar

struct ReportCard<Content: View>: View {
    var title: String
    var subtitle: String? = nil
    var trailing: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(CT.ink)
                    if let subtitle {
                        Text(verbatim: subtitle)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(CT.inkSoft)
                    }
                }
                Spacer()
                if let trailing {
                    Text(verbatim: trailing)
                        .font(CT.display(24, .heavy))
                        .foregroundStyle(CT.ink)
                        .monospacedDigit()
                }
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// Plus değilse grafikler bulanık, üstünde açma düğmesi.
struct LockedCharts<Content: View>: View {
    var locked: Bool
    var unlock: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        if locked {
            ZStack {
                VStack(spacing: 14) { content }
                    .blur(radius: 9)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(CT.gold)
                    Text(L.reportsLockedTitle)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(CT.ink)
                        .multilineTextAlignment(.center)
                    Button(action: unlock) {
                        Text(L.reportsLockedButton)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(CT.accent, in: Capsule())
                    }
                    .buttonStyle(PressableStyle())
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 24)
            }
        } else {
            VStack(spacing: 14) { content }
        }
    }
}

private struct Ring: View {
    var value: Int, total: Int, title: String, delta: String?, deltaUp: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(CT.hairline, lineWidth: 9)
                Circle()
                    .trim(from: 0, to: total > 0 ? CGFloat(value) / CGFloat(total) : 0)
                    .stroke(CT.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(verbatim: "\(value)")
                        .font(CT.display(24, .heavy))
                        .foregroundStyle(CT.ink)
                    Text(verbatim: "/ \(total)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(CT.inkSoft)
                }
            }
            .frame(width: 88, height: 88)
            Text(verbatim: title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(CT.ink)
            if let delta {
                Text(verbatim: delta)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(deltaUp ? Color.green : CT.inkSoft)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private func deltaText(_ now: Int, _ before: Int) -> (String?, Bool) {
    let d = now - before
    if d == 0 { return (L.reportsSameAsBefore, false) }
    return (d > 0 ? "▲ +\(d)" : "▼ \(d)", d > 0)
}

// MARK: - Haftalık

struct WeeklyReport: View {
    @EnvironmentObject private var store: CreatineStore
    var locked: Bool
    var unlock: () -> Void

    var body: some View {
        let days = ReportMath.days(endingAt: Date(), count: 7)
        let prev = ReportMath.days(endingAt: days[0].addingTimeInterval(-86_400), count: 7)
        let log = store.log
        let water = WaterData.mergedLog()
        let creatineNow = days.filter { log[DayKey.key(for: $0)] != nil }.count
        let creatineBefore = prev.filter { log[DayKey.key(for: $0)] != nil }.count
        let goalNow = days.filter { ReportMath.waterTotal($0, water) >= WaterData.goal(on: $0) }.count
        let goalBefore = prev.filter { ReportMath.waterTotal($0, water) >= WaterData.goal(on: $0) }.count

        VStack(spacing: 14) {
            Text(verbatim: rangeText(days))
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(CT.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                let c = deltaText(creatineNow, creatineBefore)
                Ring(value: creatineNow, total: 7, title: L.historyCreatine, delta: c.0, deltaUp: c.1)
                if store.water.enabled {
                    let w = deltaText(goalNow, goalBefore)
                    Ring(value: goalNow, total: 7, title: L.reportsWaterGoal, delta: w.0, deltaUp: w.1)
                }
            }

            creatineWeek(days, log)

            LockedCharts(locked: locked, unlock: unlock) {
                SaturationCard()
                if store.water.enabled { WeekWaterCard(days: days, water: water) }
                HourCard()
            }
        }
    }

    private func rangeText(_ days: [Date]) -> String {
        guard let a = days.first, let b = days.last else { return "" }
        return "\(a.formatted(.dateTime.day().month(.abbreviated))) – \(b.formatted(.dateTime.day().month(.abbreviated)))".uppercased()
    }

    private func creatineWeek(_ days: [Date], _ log: [String: DoseEntry]) -> some View {
        ReportCard(title: L.historyCreatine, trailing: nil) {
            HStack(spacing: 4) {
                ForEach(days, id: \.self) { d in
                    let e = log[DayKey.key(for: d)]
                    VStack(spacing: 6) {
                        Text(d, format: .dateTime.weekday(.abbreviated))
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(CT.inkSoft)
                        ZStack {
                            Circle()
                                .fill(e != nil ? CT.accent : .clear)
                                .overlay(Circle().stroke(e != nil ? CT.accent : CT.hairline, lineWidth: 2))
                            if e != nil {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 32, height: 32)
                        Text(verbatim: e.map { $0.takenAt.formatted(date: .omitted, time: .shortened) } ?? "—")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(CT.inkSoft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// Tahmini kas kreatin doygunluğu, son 30 gün.
struct SaturationCard: View {
    @EnvironmentObject private var store: CreatineStore

    var body: some View {
        let points = ReportMath.saturation(log: store.log, endingAt: Date(), count: 30)
        let now = points.last?.1 ?? 0
        let toFull = ReportMath.daysToFull(from: now, dose: store.settings.maintenanceDose)
        ReportCard(
            title: L.reportsSaturation,
            subtitle: L.reportsSaturationSub,
            trailing: now.formatted(.percent.precision(.fractionLength(0)))
        ) {
            Chart {
                ForEach(points.indices, id: \.self) { i in
                    let p = points[i]
                    AreaMark(x: .value("Day", p.0), y: .value("Saturation", p.1))
                        .foregroundStyle(LinearGradient(colors: [CT.accent.opacity(0.35), CT.accent.opacity(0)],
                                                        startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Day", p.0), y: .value("Saturation", p.1))
                        .foregroundStyle(CT.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.monotone)
                }
                RuleMark(y: .value("Full", 1.0))
                    .foregroundStyle(CT.inkSoft)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                if let last = points.last {
                    PointMark(x: .value("Day", last.0), y: .value("Saturation", last.1))
                        .foregroundStyle(CT.accent)
                        .symbolSize(70)
                }
            }
            .chartYScale(domain: 0.0...1.0)
            .chartYAxis {
                AxisMarks(values: [0, 0.5, 1]) { v in
                    AxisGridLine().foregroundStyle(CT.hairline)
                    AxisValueLabel {
                        if let d = v.as(Double.self) { Text(d.formatted(.percent.precision(.fractionLength(0)))) }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 14)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 140)

            Text(toFull > 0 ? L.reportsSaturationToFull(toFull) : L.reportsSaturationFull)
                .font(.footnote)
                .foregroundStyle(CT.inkSoft)
        }
    }
}

/// Bu haftanın suyu: günlük çubuk, kesikli hedef, ortalama çizgisi.
struct WeekWaterCard: View {
    var days: [Date]
    var water: [String: [WaterEntry]]

    var body: some View {
        let totals = days.map { ReportMath.waterTotal($0, water) }
        let drank = totals.filter { $0 > 0 }
        let avg = drank.isEmpty ? 0 : Double(drank.reduce(0, +)) / Double(drank.count)
        let goal = WaterData.goal()
        let goalDays = zip(days, totals).filter { $1 >= WaterData.goal(on: $0) }.count
        let best = totals.max() ?? 0

        ReportCard(
            title: L.waterTitle,
            subtitle: L.reportsWaterSub(ReportMath.liters(avg),
                                        (avg / Double(max(goal, 1))).formatted(.percent.precision(.fractionLength(0))))
        ) {
            Chart {
                ForEach(days.indices, id: \.self) { i in
                    let d = days[i], t = totals[i]
                    BarMark(x: .value("Day", d, unit: .day), y: .value("ml", Double(t)), width: .ratio(0.55))
                        .foregroundStyle(CT.accent.opacity(t >= WaterData.goal(on: d) ? 1 : 0.5))
                        .cornerRadius(4)
                        .annotation(position: .top) {
                            if t == best && t > 0 {
                                Text(verbatim: ReportMath.liters(t))
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundStyle(CT.ink)
                            }
                        }
                }
                RuleMark(y: .value("Goal", Double(goal)))
                    .foregroundStyle(CT.inkSoft)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                if avg > 0 {
                    RuleMark(y: .value("Average", avg))
                        .foregroundStyle(CT.loading)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { v in
                    AxisGridLine().foregroundStyle(CT.hairline)
                    AxisValueLabel {
                        if let ml = v.as(Double.self) { Text(verbatim: "\(Int(ml).litersString) L") }
                    }
                }
            }
            .frame(height: 160)

            HStack(spacing: 14) {
                legend(color: CT.accent, text: L.reportsDaily, dashed: false)
                legend(color: CT.loading, text: L.reportsAverage, dashed: false)
                legend(color: CT.inkSoft, text: L.reportsGoal, dashed: true)
            }
            Text(L.reportsGoalDays(goalDays))
                .font(.footnote)
                .foregroundStyle(CT.inkSoft)
        }
    }
}

func legend(color: Color, text: String, dashed: Bool) -> some View {
    HStack(spacing: 5) {
        Capsule()
            .stroke(color, style: StrokeStyle(lineWidth: 2, dash: dashed ? [3, 3] : []))
            .frame(width: 14, height: 2)
        Text(verbatim: text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(CT.inkSoft)
    }
}

/// Son 30 günde kreatinin alındığı saatler.
struct HourCard: View {
    @EnvironmentObject private var store: CreatineStore

    var body: some View {
        let days = ReportMath.days(endingAt: Date(), count: 30)
        let entries = days.compactMap { store.log[DayKey.key(for: $0)] }
        var counts = [Int](repeating: 0, count: 24)
        for e in entries { counts[DayKey.calendar.component(.hour, from: e.takenAt)] += 1 }
        let peak = counts.indices.max { counts[$0] < counts[$1] } ?? 0
        // En yoğun 3 saatlik pencere ve oranı.
        var bestStart = 0, bestSum = 0
        for h in 0..<22 where counts[h] + counts[h + 1] + counts[h + 2] > bestSum {
            bestSum = counts[h] + counts[h + 1] + counts[h + 2]; bestStart = h
        }
        let share = entries.isEmpty ? 0 : Double(bestSum) / Double(entries.count)

        return ReportCard(
            title: L.reportsHours,
            subtitle: L.reportsHoursSub(entries.count),
            trailing: entries.isEmpty ? nil : String(format: "%02d:00", peak)
        ) {
            Chart {
                ForEach(0..<24, id: \.self) { h in
                    BarMark(x: .value("Hour", h), y: .value("Count", Double(counts[h])), width: .ratio(0.6))
                        .foregroundStyle(h == peak ? CT.accent : CT.accent.opacity(0.45))
                        .cornerRadius(3)
                }
            }
            .chartXScale(domain: 0...23)
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { v in
                    AxisValueLabel {
                        if let h = v.as(Int.self) { Text(String(format: "%02d", h == 23 ? 24 : h)) }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 80)

            if !entries.isEmpty {
                Text(L.reportsHoursNote(share.formatted(.percent.precision(.fractionLength(0))),
                                        String(format: "%02d:00–%02d:00", bestStart, bestStart + 3)))
                    .font(.footnote)
                    .foregroundStyle(CT.inkSoft)
            }
        }
    }
}

// MARK: - Aylık

struct MonthlyReport: View {
    @EnvironmentObject private var store: CreatineStore
    var locked: Bool
    var unlock: () -> Void
    @State private var month = DayKey.startOfDay(Date())

    var body: some View {
        let all = ReportMath.monthDays(month)
        let today = DayKey.startOfDay(Date())
        let past = all.filter { $0 <= today }
        let log = store.log
        let water = WaterData.mergedLog()
        let taken = past.filter { log[DayKey.key(for: $0)] != nil }
        let grams = taken.reduce(0.0) { $0 + (log[DayKey.key(for: $1)]?.grams ?? 0) }
        let rate = past.isEmpty ? 0 : Double(taken.count) / Double(past.count)
        let waterDays = past.filter { ReportMath.waterTotal($0, water) > 0 }
        let waterAvg = waterDays.isEmpty ? 0
            : Double(waterDays.reduce(0) { $0 + ReportMath.waterTotal($1, water) }) / Double(waterDays.count)
        let goalDays = past.filter { ReportMath.waterTotal($0, water) >= WaterData.goal(on: $0) && ReportMath.waterTotal($0, water) > 0 }.count

        VStack(spacing: 14) {
            HStack {
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(month, format: .dateTime.month(.wide).year())
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
                    .disabled(DayKey.calendar.isDate(month, equalTo: today, toGranularity: .month))
            }
            .foregroundStyle(CT.ink)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                tile(L.historyCreatine, "\(taken.count) / \(past.count)")
                tile(L.reportsConsistency, rate.formatted(.percent.precision(.fractionLength(0))))
                tile(L.reportsTotalCreatine, "\(grams.gramString) g")
                if store.water.enabled {
                    tile(L.reportsWaterGoal, L.reportsDays(goalDays))
                }
            }

            LockedCharts(locked: locked, unlock: unlock) {
                ReportCard(title: L.reportsCreatineCalendar) {
                    heatmap(all) { d in
                        guard d <= today else { return nil }
                        return log[DayKey.key(for: d)] != nil ? 3 : -1
                    }
                }
                if store.water.enabled {
                    ReportCard(title: L.reportsWaterHeatmap, subtitle: nil) {
                        heatmap(all) { d in
                            guard d <= today else { return nil }
                            let t = ReportMath.waterTotal(d, water)
                            let r = Double(t) / Double(max(WaterData.goal(on: d), 1))
                            return t == 0 ? -1 : r < 0.5 ? 0 : r < 0.75 ? 1 : r < 1 ? 2 : 3
                        }
                        HStack(spacing: 5) {
                            Text(L.reportsLess).font(.caption2).foregroundStyle(CT.inkSoft)
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 3).fill(level(i)).frame(width: 20, height: 11)
                            }
                            Text(L.reportsGoal).font(.caption2).foregroundStyle(CT.inkSoft)
                        }
                    }
                    MonthWaterTrend(days: past, water: water, average: waterAvg)
                    WeekdayCard(days: past, water: water)
                }
            }
        }
    }

    private func shift(_ delta: Int) {
        guard let next = DayKey.calendar.date(byAdding: .month, value: delta, to: month) else { return }
        withAnimation(.snappy) { month = next }
    }

    private func tile(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(CT.inkSoft)
            Text(verbatim: value)
                .font(CT.display(24, .heavy))
                .foregroundStyle(CT.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    /// Tek renk (açık = az, koyu/parlak = hedef).
    private func level(_ i: Int) -> Color {
        [CT.accent.opacity(0.18), CT.accent.opacity(0.4), CT.accent.opacity(0.7), CT.accent][max(0, min(3, i))]
    }

    /// Ay takvimi ısı haritası. `value`: nil = gelecek, -1 = boş, 0…3 = seviye.
    private func heatmap(_ days: [Date], value: @escaping (Date) -> Int?) -> some View {
        let cal = DayKey.calendar
        let first = days.first ?? Date()
        let lead = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        let cells: [Date?] = Array(repeating: nil, count: lead) + days.map { Optional($0) }
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, d in
                if let d {
                    let v = value(d)
                    Text(verbatim: "\(cal.component(.day, from: d))")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(v == 3 ? Color.white : v == nil ? CT.inkSoft.opacity(0.5) : CT.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(v.map { $0 < 0 ? CT.hairline.opacity(0.6) : level($0) } ?? .clear,
                                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    Color.clear.frame(height: 34)
                }
            }
        }
    }
}

/// Ayın su trendi: günlük çizgi, 7 günlük ortalama, hedef.
struct MonthWaterTrend: View {
    var days: [Date]
    var water: [String: [WaterEntry]]
    var average: Double

    var body: some View {
        let totals = days.map { ReportMath.waterTotal($0, water) }
        let rolling: [Double] = totals.indices.map { i in
            let window = totals[max(0, i - 6)...i]
            return Double(window.reduce(0, +)) / Double(window.count)
        }
        let goal = WaterData.goal()

        ReportCard(title: L.reportsWaterTrend, subtitle: L.reportsAverageL(ReportMath.liters(average))) {
            Chart {
                ForEach(days.indices, id: \.self) { i in
                    let d = days[i], t = totals[i]
                    LineMark(x: .value("Day", d), y: .value("ml", Double(t)), series: .value("S", "daily"))
                        .foregroundStyle(CT.accent.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    if t >= WaterData.goal(on: d) && t > 0 {
                        PointMark(x: .value("Day", d), y: .value("ml", Double(t)))
                            .foregroundStyle(CT.accent)
                            .symbolSize(40)
                    }
                }
                ForEach(days.indices, id: \.self) { i in
                    LineMark(x: .value("Day", days[i]), y: .value("ml", rolling[i]), series: .value("S", "avg"))
                        .foregroundStyle(CT.loading)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.monotone)
                }
                RuleMark(y: .value("Goal", Double(goal)))
                    .foregroundStyle(CT.inkSoft)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
            .chartYAxis {
                AxisMarks { v in
                    AxisGridLine().foregroundStyle(CT.hairline)
                    AxisValueLabel {
                        if let ml = v.as(Double.self) { Text(verbatim: "\(Int(ml).litersString) L") }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .frame(height: 160)

            HStack(spacing: 14) {
                legend(color: CT.accent, text: L.reportsDaily, dashed: false)
                legend(color: CT.loading, text: L.reportsRolling, dashed: false)
                legend(color: CT.inkSoft, text: L.reportsGoal, dashed: true)
            }
        }
    }
}

/// Haftanın günlerine göre ortalama su.
struct WeekdayCard: View {
    var days: [Date]
    var water: [String: [WaterEntry]]

    var body: some View {
        let cal = DayKey.calendar
        var sums = [Int: (Int, Int)]()      // weekday → (toplam, gün)
        for d in days {
            let t = ReportMath.waterTotal(d, water)
            guard t > 0 else { continue }
            let w = cal.component(.weekday, from: d)
            let cur = sums[w] ?? (0, 0)
            sums[w] = (cur.0 + t, cur.1 + 1)
        }
        let order = (0..<7).map { (cal.firstWeekday - 1 + $0) % 7 + 1 }
        let avgs = order.map { w -> (Int, Double) in
            let s = sums[w] ?? (0, 0)
            return (w, s.1 > 0 ? Double(s.0) / Double(s.1) : 0)
        }
        let maxV = max(avgs.map(\.1).max() ?? 1, 1)
        let best = avgs.max { $0.1 < $1.1 }
        let worst = avgs.filter { $0.1 > 0 }.min { $0.1 < $1.1 }
        let names = cal.weekdaySymbols

        return ReportCard(title: L.reportsWeekday) {
            VStack(spacing: 8) {
                ForEach(avgs.indices, id: \.self) { i in
                    let w = avgs[i].0, v = avgs[i].1
                    HStack(spacing: 10) {
                        Text(verbatim: cal.shortWeekdaySymbols[w - 1])
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(CT.inkSoft)
                            .frame(width: 36, alignment: .leading)
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(CT.hairline.opacity(0.6))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(w == best?.0 ? CT.accent : CT.accent.opacity(0.5))
                                    .frame(width: g.size.width * CGFloat(v / maxV))
                            }
                        }
                        .frame(height: 14)
                        Text(verbatim: v > 0 ? "\(ReportMath.liters(v)) L" : "—")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(CT.ink)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
            if let best, let worst, best.1 > 0 {
                Text(L.reportsWeekdayNote(names[best.0 - 1], names[worst.0 - 1]))
                    .font(.footnote)
                    .foregroundStyle(CT.inkSoft)
            }
        }
    }
}
