import AppIntents
import WidgetKit

// Başlık ve açıklamalar Localizable.xcstrings'teki anahtarlardan okunuyor.
// App Intents bunları derleme zamanında çıkardığı için literal kalmak zorunda.

struct MarkTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.log.title"
    static var description = IntentDescription("intent.log.desc")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        Persistence.markTaken()
        await NotificationManager.reschedule()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct UndoTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.undo.title"
    static var description = IntentDescription("intent.undo.desc")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        Persistence.undo()
        await NotificationManager.reschedule()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
