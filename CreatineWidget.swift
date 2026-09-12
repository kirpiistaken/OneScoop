import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline

struct CreatineEntry: TimelineEntry {
    let date: Date
    let status: DayStatus

    static let placeholder = CreatineEntry(
        date: Date(),
        status: DayStatus(dateKey: DayKey.today, isTaken: false, grams: 5, isLoadingDay: false, streak: 3)
    )
}

struct CreatineProvider: TimelineProvider {
    func placeholder(in context: Context) -> CreatineEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (CreatineEntry) -> Void) {
        completion(CreatineEntry(date: Date(), status: Persistence.currentStatus()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CreatineEntry>) -> Void) {
        let entry = CreatineEntry(date: Date(), status: Persistence.currentStatus())
        // Gece yarısı yeni gün başlar, widget kendini sıfırlar.
        completion(Timeline(entries: [entry], policy: .after(DayKey.nextMidnight)))
    }
}

// MARK: - Views

struct CreatineWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CreatineEntry

    var body: some View {
        switch family {
        case .systemMedium: medium
        case .accessoryCircular: circular
        default: small
        }
    }

    private var accent: Color { entry.status.isLoadingDay ? CT.loading : CT.accent }

    // MARK: Small

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.status.isTaken {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(accent)
                Text("Dose logged")
                    .font(CT.display(17, .bold))
                    .foregroundStyle(CT.ink)
                Text("\(entry.status.grams.gramString) g today")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
                Spacer(minLength: 0)
                Button(intent: UndoTakenIntent()) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(CT.inkSoft)
                }
                .buttonStyle(.plain)
            } else {
                Text("Did you take creatine today?")
                    .font(CT.display(17, .bold))
                    .foregroundStyle(CT.ink)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Button(intent: MarkTakenIntent()) {
                    Text("Yes")
                        .font(CT.display(18, .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(accent, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Medium

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.status.isTaken ? "You took your daily dose of creatine" : "Did you take creatine today?")
                    .font(CT.display(20, .bold))
                    .foregroundStyle(CT.ink)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text("\(entry.status.grams.gramString) g")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(CT.inkSoft)
                    if entry.status.streak > 1 {
                        Text("· \(entry.status.streak) day streak")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(CT.inkSoft)
                    }
                }
                Spacer(minLength: 0)
            }

            if entry.status.isTaken {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(accent)
                    Button(intent: UndoTakenIntent()) {
                        Text("Undo")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(CT.inkSoft)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: 96)
            } else {
                Button(intent: MarkTakenIntent()) {
                    Text("Yes")
                        .font(CT.display(26, .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 96, height: 96)
                        .background(accent, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Lock screen

    @ViewBuilder
    private var circular: some View {
        // İki farklı AppIntent tipi olduğu için ternary yerine if/else şart.
        if entry.status.isTaken {
            Button(intent: UndoTakenIntent()) { circularFace }
                .buttonStyle(.plain)
        } else {
            Button(intent: MarkTakenIntent()) { circularFace }
                .buttonStyle(.plain)
        }
    }

    private var circularFace: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: entry.status.isTaken ? "checkmark" : "drop.fill")
                .font(.system(size: 20, weight: .bold))
        }
    }
}

// MARK: - Widget

struct CreatineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppGroup.widgetKind, provider: CreatineProvider()) { entry in
            CreatineWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    entry.status.isTaken ? CT.accentSoft : CT.bg
                }
        }
        .configurationDisplayName("Creatine")
        .description("Log today's creatine without opening the app.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

@main
struct CreatineWidgetBundle: WidgetBundle {
    var body: some Widget {
        CreatineWidget()
    }
}
