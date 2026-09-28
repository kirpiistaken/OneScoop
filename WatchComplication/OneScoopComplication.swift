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

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ComplicationEntry

    private var s: WatchDayState { entry.state }
    private var icon: String { s.isTaken ? "checkmark.circle.fill" : "drop.fill" }
    private var statusText: String { s.isTaken ? L.widgetDoseLogged : L.complicationNotYet }

    var body: some View {
        switch family {
        case .accessoryCorner:
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .widgetAccentable()
                .widgetLabel {
                    Text(s.streak > 1 ? L.todayStreak(s.streak) : statusText)
                }

        case .accessoryInline:
            Label(s.streak > 1 && s.isTaken ? L.todayStreak(s.streak) : statusText,
                  systemImage: icon)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label(statusText, systemImage: icon)
                    .font(.headline)
                    .widgetAccentable()
                if s.streak > 1 {
                    Text(L.todayStreak(s.streak))
                        .font(.body)
                }
                Text(verbatim: "OneScoop")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        default: // .accessoryCircular
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: icon)
                        .font(.system(size: s.streak > 1 ? 18 : 22, weight: .bold))
                        .widgetAccentable()
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
