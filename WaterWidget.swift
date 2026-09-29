import AppIntents
import SwiftUI
import WidgetKit

// 2.0 — Su widget'ı ve Denetim Merkezi'nden su ekleme. Widget uzantısı target'ında.

struct WaterTimelineEntry: TimelineEntry {
    let date: Date
    let total: Int
    let goal: Int
    let cups: [WaterCup]
    let defaultCup: WaterCup
    let hasEntries: Bool
    let enabled: Bool
    let unlocked: Bool
    let creatineTaken: Bool

    var fraction: Double { goal > 0 ? min(1, Double(total) / Double(goal)) : 0 }
    /// Her eklemede dalga biraz kaysın; WidgetKit iki durum arasını canlandırıyor.
    var wavePhase: Double { Double(total) / 250 * .pi / 2 }

    static func now() -> WaterTimelineEntry {
        let s = WaterData.loadSettings()
        let today = WaterData.entries()
        let undoable = !WaterData.localEntries().isEmpty
        return WaterTimelineEntry(
            date: Date(),
            total: today.reduce(0) { $0 + $1.ml },
            goal: WaterData.goal(),
            cups: s.cups,
            defaultCup: s.defaultCup,
            hasEntries: undoable,
            enabled: s.enabled,
            unlocked: PlusAccess.isUnlocked,
            creatineTaken: Persistence.isTaken()
        )
    }

    static let placeholder = WaterTimelineEntry(
        date: Date(), total: 1250, goal: 2500,
        cups: WaterCup.defaults, defaultCup: WaterCup.defaults[0], hasEntries: true,
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

    /// Su açık ama OneScoop+ yok: widget'a dokununca satın alma ekranı.
    private var needsPlus: Bool { entry.enabled && !entry.unlocked }

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular: circular
            case .accessoryRectangular: rectangular
            case .systemMedium: medium
            case .systemLarge: large
            default: small
            }
        }
        .widgetURL(needsPlus ? URL(string: "onescoop://plus") : nil)
    }

    // MARK: Ortak parçalar

    private func glass(width: CGFloat, height: CGFloat) -> some View {
        WaterGlass(fraction: entry.fraction, wavePhase: entry.wavePhase)
            .frame(width: width, height: height)
            .animation(.spring(response: 0.7, dampingFraction: 0.75), value: entry.total)
    }

    private func totals(_ size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "\(entry.total.litersString) L")
                .font(CT.display(size, .bold))
                .foregroundStyle(CT.ink)
                .contentTransition(.numericText())
            Text(verbatim: "/ \(entry.goal.litersString) L")
                .font(.system(size: size * 0.6, weight: .medium, design: .rounded))
                .foregroundStyle(CT.inkSoft)
        }
    }

    /// Butonların yerine: su kapalıysa kısa not, Plus yoksa sarı taç + "OneScoop+".
    @ViewBuilder
    private var lockedNote: some View {
        if entry.enabled {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CT.gold)
                    .frame(width: 30, height: 30)
                    .background(CT.goldSoft, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    (Text(verbatim: "OneScoop").foregroundStyle(CT.ink)
                     + Text(verbatim: "+").foregroundStyle(CT.gold))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                    Text(L.widgetWaterPlus)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(CT.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else {
            Text(L.widgetWaterOff)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(CT.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func cupButton(_ cup: WaterCup, circle: CGFloat) -> some View {
        Button(intent: AddWaterIntent(ml: cup.ml)) {
            VStack(spacing: 4) {
                CupIcon(kind: cup.kind)
                    .fill(CT.accent)
                    .frame(width: circle * 0.54, height: circle * 0.52)
                    .frame(width: circle, height: circle)
                    .background(CT.accent.opacity(0.14), in: Circle())
                Text(verbatim: "\(cup.ml)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .buttonStyle(.plain)
    }

    private func undoButton(circle: CGFloat) -> some View {
        Button(intent: UndoLastWaterIntent()) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: circle * 0.36, weight: .bold))
                .foregroundStyle(entry.hasEntries ? CT.ink : CT.inkSoft.opacity(0.4))
                .frame(width: circle, height: circle)
                .background(CT.surface, in: Circle())
                .overlay(Circle().stroke(CT.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!entry.hasEntries)
    }

    /// Üç kap + hemen yanında geri al; çağıran yer ortalıyor.
    private func buttonRow(circle: CGFloat, spacing: CGFloat) -> some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(entry.cups) { cupButton($0, circle: circle) }
            undoButton(circle: circle * 0.8)
                .padding(.top, circle * 0.1)
        }
    }

    /// Bastıkça dolan ince çubuk.
    private var bar: some View {
        WaterBar(fraction: entry.fraction)
            .frame(height: 6)
            .animation(.spring(response: 0.7, dampingFraction: 0.8), value: entry.total)
    }

    // MARK: Küçük: bardak + varsayılan kap

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                glass(width: 36, height: 52)
                Spacer()
                totals(20)
            }
            Spacer(minLength: 0)
            if ready {
                Button(intent: AddWaterIntent(ml: entry.defaultCup.ml)) {
                    Text(verbatim: "+\(entry.defaultCup.ml) ml")
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
                lockedNote
            }
        }
    }

    // MARK: Orta: bardak ve toplam solda, üç kap + geri al ortada, altta çubuk

    private var medium: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    glass(width: 38, height: 54)
                    totals(18)
                }
                .fixedSize()
                if ready {
                    buttonRow(circle: 48, spacing: 8)
                        .frame(maxWidth: .infinity)
                } else {
                    lockedNote
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxHeight: .infinity)
            bar
        }
    }

    // MARK: Büyük: kocaman bardak, altta üç kap + geri al

    private var large: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(L.waterTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
                Spacer()
                HStack(spacing: 5) {
                    ScoopShape(check: entry.creatineTaken)
                        .fill(entry.creatineTaken ? CT.accent : CT.inkSoft)
                        .frame(width: 16, height: 16)
                    Text(entry.creatineTaken ? L.widgetDoseLogged : L.complicationNotYet)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(CT.inkSoft)
                        .lineLimit(1)
                }
            }

            HStack(alignment: .bottom, spacing: 20) {
                glass(width: 96, height: 138)
                totals(34)
                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity)

            bar

            if ready {
                buttonRow(circle: 62, spacing: 14)
                    .frame(maxWidth: .infinity)
            } else {
                lockedNote
            }
        }
    }

    // MARK: Kilit ekranı

    @ViewBuilder
    private var circular: some View {
        if ready {
            Button(intent: AddWaterIntent(ml: entry.defaultCup.ml)) { circularFace }
                .buttonStyle(.plain)
        } else {
            circularFace
        }
    }

    private var circularFace: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                ZStack {
                    GlassShape().stroke(.primary.opacity(0.5), lineWidth: 1.5)
                    WaveFill(fraction: entry.fraction, phase: entry.wavePhase)
                        .fill(.primary)
                        .clipShape(GlassShape())
                }
                .frame(width: 20, height: 26)
                .widgetAccentable()
                .overlay(alignment: .topTrailing) {
                    if needsPlus {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8, weight: .bold))
                            .offset(x: 8, y: -4)
                    }
                }
                Text(verbatim: entry.total.litersString)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
        }
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            ZStack {
                GlassShape().stroke(.primary.opacity(0.5), lineWidth: 1.5)
                WaveFill(fraction: entry.fraction, phase: entry.wavePhase)
                    .fill(.primary)
                    .clipShape(GlassShape())
            }
            .frame(width: 24, height: 34)
            .widgetAccentable()

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "\(entry.total.litersString) / \(entry.goal.litersString) L")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .widgetAccentable()
                if needsPlus {
                    Label {
                        Text(verbatim: "OneScoop+")
                    } icon: {
                        Image(systemName: "crown.fill")
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                } else {
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Denetim Merkezi: +1 kap

@available(iOS 18.0, *)
struct AddWaterControl: ControlWidget {
    static let kind = "com.atalay.creatinetracker.AddWaterControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind, provider: WaterTotalProvider()) { total in
            // Plus yoksa taç ve "OneScoop+" görünüyor; dokunmak bir şey eklemiyor.
            ControlWidgetButton(action: AddWaterIntent()) {
                Label {
                    Text(verbatim: PlusAccess.isUnlocked ? "\(total.litersString) L" : "OneScoop+")
                } icon: {
                    Image(systemName: PlusAccess.isUnlocked ? "waterbottle.fill" : "crown.fill")
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

/// Hedefe göre dolan yatay çubuk (widget).
struct WaterBar: View {
    var fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(CT.accent.opacity(0.15))
                Capsule()
                    .fill(CT.accent)
                    .frame(width: max(fraction > 0 ? geo.size.height : 0,
                                      geo.size.width * min(1, max(0, fraction))))
            }
        }
    }
}
