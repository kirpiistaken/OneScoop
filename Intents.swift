import AppIntents
import WidgetKit

/// Widget üzerindeki "Yes" butonu. Uygulama açılmadan çalışır (iOS 17+).
struct MarkTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "Log today's creatine"
    static var description = IntentDescription("Marks today's creatine dose as taken.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        Persistence.markTaken()
        await NotificationManager.reschedule()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Yanlışlıkla basıldıysa geri alma.
struct UndoTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "Undo today's creatine"
    static var description = IntentDescription("Removes today's creatine entry.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        Persistence.undo()
        await NotificationManager.reschedule()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
