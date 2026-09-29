import AppIntents
import SwiftUI
import WidgetKit

// 2.0 — Su widget'ı ve Denetim Merkezi'nden su ekleme. Widget uzantısı target'ında.

struct WaterTimelineEntry: TimelineEntry {
    let date: Date
    let total: Int
    let goal: Int
    let cupMl: Int
    let enabled: Bool
    let unlocked: Bool
    let creatineTaken: Bool

    var fraction: Double { goal > 0 ? min(1, Double(total) / Double(goal)) : 0 }

    static func now() -> WaterTimelineEntry {
        let s = WaterData.loadSettings()
        return WaterTimelineEntry(
            date: Date(),
            total: WaterData.total(),
            goal: s.goalMl,
            cupMl: s.defaultCup.ml,
            enabled: s.enabled,
            unlocked: PlusAccess.isUnlocked,
            creatineTaken: Persistence.isTaken()
        )
    }

    static let placeholder = WaterTimelineEntry(
        date: Date(), total: 1250, goal: 2500, cupMl: 250,
        enabled: true, unlocked: true, creatineTaken: true
    )
}

struct WaterProvider: TimelineProvider {
    func placeholder(in context: Context) -> WaterTimelineEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (WaterTimelineEntry) -> Void) {
        completion(context.isPreview ? .placeholder : .now())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterTimelineEntry>) -> Void) {
        completion(Timeline(entries: [.now()], policy: .after(DayKey.nextMidnight)))
    }
}

struct WaterWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WaterTimelineEntry

    private var ready: Bool { entry.enabled && entry.unlocked }

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        default: small
        }
    }

    // MARK: Küçük: halka + tek dokunuş

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                ZStack {
                    Circle().stroke(CT.accent.opacity(0.15), lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: entry.fraction)
                        .stroke(CT.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 44, height: 44)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(verbatim: "\(entry.total.litersString) L")
                        .font(CT.display(20, .bold))
                        .foregroundStyle(CT.ink)
                    Text(verbatim: "/ \(entry.goal.litersString) L")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(CT.inkSoft)
                }
            }

            Spacer(minLength: 0)

            if ready {
                Button(intent: AddWaterIntent(ml: entry.cupMl)) {
                    Text(verbatim: "+\(entry.cupMl) ml")
                        .font(CT.display(17, .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(CT.accent, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                Text(entry.enabled ? L.widgetWaterPlus : L.widgetWaterOff)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Kilit ekranı

    @ViewBuilder
    private var circular: some View {
        if ready {
            Button(intent: AddWaterIntent(ml: entry.cupMl)) { gauge }
                .buttonStyle(.plain)
        } else {
            gauge
        }
    }

    private var gauge: some View {
        Gauge(value: entry.fraction) {
            EmptyView()
        } currentValueLabel: {
            Text(verbatim: entry.total.litersString)
                .font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: "\(entry.total.litersString) / \(entry.goal.litersString) L")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .widgetAccentable()
            Gauge(value: entry.fraction) { EmptyView() }
                .gaugeStyle(.accessoryLinearCapacity)
            HStack(spacing: 4) {
                ScoopShape(check: entry.creatineTaken)
                    .fill(.primary)
                    .frame(width: 13, height: 13)
                Text(entry.creatineTaken ? L.widgetDoseLogged : L.complicationNotYet)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .lineLimit(1)
            }
        }
    }
}

struct WaterWidget: Widget {
    static let kind = "com.atalay.creatinetracker.WaterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: WaterProvider()) { entry in
            WaterWidgetView(entry: entry)
                .containerBackground(for: .widget) { CT.bg }
        }
        .configurationDisplayName(Text(L.widgetWaterName))
        .description(Text(L.widgetWaterDesc))
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Denetim Merkezi: +1 kap

@available(iOS 18.0, *)
struct AddWaterControl: ControlWidget {
    static let kind = "com.atalay.creatinetracker.AddWaterControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind, provider: WaterTotalProvider()) { total in
            ControlWidgetButton(action: AddWaterIntent()) {
                Label {
                    Text(verbatim: "\(total.litersString) L")
                } icon: {
                    Image(systemName: "waterbottle.fill")
                }
            }
        }
        .displayName("widget.water_name")
        .description("control.water_desc")
    }
}

@available(iOS 18.0, *)
struct WaterTotalProvider: ControlValueProvider {
    var previewValue: Int { 1250 }

    func currentValue() async throws -> Int {
        WaterData.total()
    }
}
