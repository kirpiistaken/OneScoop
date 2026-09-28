import SwiftUI
import WidgetKit

/// Saat kadranı göstergesi. Bugün alınıp alınmadığını ve seriyi gösterir;
/// dokununca saat uygulaması açılır, oradan tek dokunuşla kaydedilir.
///
/// Veriyi saat uygulamasının App Group'a yazdığı son durumdan okur.

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let state: WatchDayState
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: Date(), state: WatchDayState(isTaken: false, streak: 5, grams: 5, onboarded: true))
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        completion(ComplicationEntry(date: Date(), state: WatchPayload.state(WatchPayload.loadStored(), on: Date())))
    }

    /// Şimdi ve gece yarısı için iki giriş: gün değişince, telefon ya da saat
    /// uygulaması açılmamış olsa bile gösterge "henüz alınmadı"ya döner.
    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let payload = WatchPayload.loadStored()
        let now = Date()
        let midnight = DayKey.nextMidnight
        let entries = [
            ComplicationEntry(date: now, state: WatchPayload.state(payload, on: now)),
            ComplicationEntry(date: midnight, state: WatchPayload.state(payload, on: midnight))
        ]
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

/// Uygulama logosundaki kepçe, vektör olarak çizilmiş. Koordinatlar logonun
/// 1254 piksellik orijinalinden alındı. Görsel dosyası yerine şekil
/// kullanıyoruz: saat kadranları görsel yüklemede çok titiz, şekil ise her
/// boyutta keskin ve kadranın rengine göre boyanıyor.
struct ScoopShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 870
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.midX + (x - 672) * s, y: rect.midY + (y - 635) * s)
        }
        func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
            let o = pt(cx - rx, cy - ry)
            return Path(ellipseIn: CGRect(x: o.x, y: o.y, width: rx * 2 * s, height: ry * 2 * s))
        }

        let rim = ellipse(507, 540, 253, 100)                 // ağız dış halkası
        let o = pt(256, 540)
        let body = Path(CGRect(x: o.x, y: o.y, width: 501 * s, height: 260 * s))
        let bottom = ellipse(506.5, 800, 250.5, 125)          // yuvarlak dip
        let hole = ellipse(507, 538, 221, 69)                 // ağız iç boşluğu

        let handle = Path { p in
            p.move(to: pt(768, 518))
            p.addLine(to: pt(1040, 395))
        }
        .strokedPath(StrokeStyle(lineWidth: 100 * s, lineCap: .round))

        return rim.union(body).union(bottom)
            .subtracting(hole)
            .union(handle)
    }
}

/// Kepçe; alındıysa köşesinde küçük bir tik.
struct ScoopMark: View {
    let taken: Bool
    var size: CGFloat

    var body: some View {
        ScoopShape()
            .fill(.primary)
            .frame(width: size, height: size)
            .overlay(alignment: .bottomTrailing) {
                if taken {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: size * 0.5, weight: .bold))
                        .background(Circle().fill(.black).padding(1))
                        .offset(x: size * 0.12, y: size * 0.08)
                }
            }
            .widgetAccentable()
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ComplicationEntry

    private var s: WatchDayState { entry.state }
    private var statusText: String { s.isTaken ? L.widgetDoseLogged : L.complicationNotYet }

    var body: some View {
        switch family {
        case .accessoryCorner:
            ScoopMark(taken: s.isTaken, size: 22)
                .widgetLabel {
                    Text(s.streak > 1 ? L.todayStreak(s.streak) : statusText)
                }

        case .accessoryInline:
            // Satır içi gösterge sadece metin ve sistem simgesi alıyor, özel
            // şekil çizilemiyor. Uygulamanın adıyla başlatıyoruz ki belli olsun.
            Text(verbatim: "OneScoop · ")
                + Text(s.streak > 1 && s.isTaken ? L.todayStreak(s.streak) : statusText)

        case .accessoryRectangular:
            HStack(spacing: 8) {
                ScoopMark(taken: s.isTaken, size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text(statusText)
                        .font(.headline)
                        .widgetAccentable()
                    if s.streak > 1 {
                        Text(L.todayStreak(s.streak))
                            .font(.body)
                    }
                    Text(verbatim: "OneScoop")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        default: // .accessoryCircular
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    ScoopMark(taken: s.isTaken, size: s.streak > 1 ? 20 : 26)
                    if s.streak > 1 {
                        Text(verbatim: "\(s.streak)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                }
            }
        }
    }
}

@main
struct OneScoopComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "OneScoopComplication", provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text(verbatim: "OneScoop"))
        .description(Text(L.complicationDescription))
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}
