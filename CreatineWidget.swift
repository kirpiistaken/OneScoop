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
                Text(L.widgetDoseLogged)
                    .font(CT.display(17, .bold))
                    .foregroundStyle(CT.ink)
                    .minimumScaleFactor(0.8)
                Text(L.widgetGramsToday(entry.status.grams.gramString))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
                Spacer(minLength: 0)
                Button(intent: UndoTakenIntent()) {
                    Label(L.todayUndo, systemImage: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(CT.inkSoft)
                }
                .buttonStyle(.plain)
            } else {
                Text(L.todayQuestion)
                    .font(CT.display(17, .bold))
                    .foregroundStyle(CT.ink)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Button(intent: MarkTakenIntent()) {
                    Text(L.todayYes)
                        .font(CT.display(18, .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
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
                Text(entry.status.isTaken ? L.todayDoneTitle : L.todayQuestion)
                    .font(CT.display(20, .bold))
                    .foregroundStyle(CT.ink)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(verbatim: "\(entry.status.grams.gramString) g")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(CT.inkSoft)
                    if entry.status.streak > 1 {
                        Text(L.widgetStreak(entry.status.streak))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(CT.inkSoft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
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
                        Text(L.todayUndo)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(CT.inkSoft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: 96)
            } else {
                Button(intent: MarkTakenIntent()) {
                    Text(L.todayYes)
                        .font(CT.display(26, .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, 8)
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
        .configurationDisplayName(Text(verbatim: "OneScoop"))
        .description(Text(L.widgetDescription))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

@main
struct CreatineWidgetBundle: WidgetBundle {
    var body: some Widget {
        CreatineWidget()
    }
}
