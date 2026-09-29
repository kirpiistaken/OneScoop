import SwiftUI

// 2.0 — Haftalık özet (OneScoop+). Sadece uygulama target'ında.
// Son 7 gün (bugün dahil): su ortalaması, hedef günleri, en çok içilen saat
// aralığı, günün en sessiz bölümü ve kreatin tutarlılığı. Tek, sade bir ekran.

struct WeeklyInsight {
    enum DayPart: CaseIterable { case morning, afternoon, evening }

    let days: [Date]              // eskiden yeniye, 7 gün
    let waterTotals: [Int]
    let goals: [Int]
    let creatineDays: Int
    let peakStartHour: Int?       // en çok içilen 2 saatlik aralığın başı
    let quietPart: DayPart?

    var drankDays: [Int] { waterTotals.filter { $0 > 0 } }
    var average: Int { drankDays.isEmpty ? 0 : drankDays.reduce(0, +) / drankDays.count }
    var goalDays: Int { zip(waterTotals, goals).filter { $0 >= $1 }.count }
    var hasWater: Bool { !drankDays.isEmpty }

    static func compute(now: Date = Date()) -> WeeklyInsight {
        let cal = DayKey.calendar
        let today = DayKey.startOfDay(now)
        let days = (0..<7).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        let water = WaterData.mergedLog()
        let creatine = Persistence.loadLog()

        let entries = days.flatMap { water[DayKey.key(for: $0)] ?? [] }
        var byHour = [Int](repeating: 0, count: 24)
        for e in entries { byHour[cal.component(.hour, from: e.at)] += e.ml }

        // En yoğun 2 saatlik aralık
        var peak: Int?
        var best = 0
        for h in 0..<23 where byHour[h] + byHour[h + 1] > best {
            best = byHour[h] + byHour[h + 1]
            peak = h
        }

        // Günün en az içilen bölümü (en az 3 günlük veriyle)
        var quiet: DayPart?
        let parts: [(DayPart, ClosedRange<Int>)] = [(.morning, 5...11), (.afternoon, 12...16), (.evening, 17...23)]
        let withWater = days.filter { !(water[DayKey.key(for: $0)] ?? []).isEmpty }.count
        if withWater >= 3 {
            quiet = parts.min { a, b in
                a.1.reduce(0) { $0 + byHour[$1] } < b.1.reduce(0) { $0 + byHour[$1] }
            }?.0
        }

        return WeeklyInsight(
            days: days,
            waterTotals: days.map { (water[DayKey.key(for: $0)] ?? []).reduce(0) { $0 + $1.ml } },
            goals: days.map { WaterData.goal(on: $0) },
            creatineDays: days.filter { creatine[DayKey.key(for: $0)] != nil }.count,
            peakStartHour: best > 0 ? peak : nil,
            quietPart: quiet
        )
    }
}

struct InsightsView: View {
    @EnvironmentObject private var store: CreatineStore
    @Environment(\.dismiss) private var dismiss
    private let insight = WeeklyInsight.compute()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if store.water.enabled {
                        bars
                            .padding(16)
                            .background(CT.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        if store.water.enabled {
                            if insight.hasWater {
                                row("drop.fill", L.insightsAverage(insight.average.litersString))
                                row("target", L.insightsGoalDays(insight.goalDays, 7))
                                if let h = insight.peakStartHour {
                                    row("clock.fill", L.insightsPeak(String(format: "%02d:00–%02d:00", h, h + 2)))
                                }
                                if let quiet = insight.quietPart {
                                    row("moon.zzz.fill", quietText(quiet))
                                }
                            } else {
                                row("drop", L.insightsNoWater)
                            }
                        }
                        row("checkmark.circle.fill", L.insightsCreatine(insight.creatineDays, 7))
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CT.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(20)
            }
            .background(CT.bg.ignoresSafeArea())
            .navigationTitle(L.insightsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.commonDone) { dismiss() }
                }
            }
        }
    }

    /// 7 günlük su çubukları; hedefe ulaşılan gün koyu mavi.
    private var bars: some View {
        let maxValue = max(insight.waterTotals.max() ?? 0, insight.goals.max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(insight.days.enumerated()), id: \.offset) { i, day in
                VStack(spacing: 6) {
                    Text(verbatim: insight.waterTotals[i] > 0 ? insight.waterTotals[i].litersString : "")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(CT.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(insight.waterTotals[i] >= insight.goals[i] ? CT.accent : CT.accent.opacity(0.35))
                        .frame(height: max(4, 120 * CGFloat(insight.waterTotals[i]) / CGFloat(maxValue)))
                    Text(day, format: .dateTime.weekday(.narrow))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(DayKey.key(for: day) == DayKey.today ? CT.accent : CT.inkSoft)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 170, alignment: .bottom)
        .accessibilityHidden(true)
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(CT.accent)
                .frame(width: 22)
            Text(text)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(CT.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func quietText(_ part: WeeklyInsight.DayPart) -> String {
        switch part {
        case .morning: L.insightsQuietMorning
        case .afternoon: L.insightsQuietAfternoon
        case .evening: L.insightsQuietEvening
        }
    }
}
