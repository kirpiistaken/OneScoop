import AppIntents
import WidgetKit

// Başlık ve açıklamalar Localizable.xcstrings'teki anahtarlardan okunuyor.
// App Intents bunları derleme zamanında çıkardığı için literal kalmak zorunda.

struct MarkTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.log.title"
    static var description = IntentDescription("intent.log.desc")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        // Eylem düğmesine iki kez basmak ikinci kez kaydetmesin.
        if !Persistence.isTaken() {
            Persistence.markTaken()
        }
        await NotificationManager.reschedule()
        IntentRefresh.all()
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
        IntentRefresh.all()
        return .result()
    }
}

/// 2.0 — Su ekle. `ml` 0 ise kullanıcının varsayılan kabı kullanılır.
/// Widget, Denetim Merkezi ve Siri buradan geçiyor.
struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.water.title"
    static var description = IntentDescription("intent.water.desc")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "intent.water.amount", default: 0)
    var ml: Int

    init() {}
    init(ml: Int) { self.ml = ml }

    func perform() async throws -> some IntentResult {
        let settings = WaterData.loadSettings()
        // Su kapalıysa ya da Plus yoksa uygulama dışından ekleme yapılmıyor;
        // widget bu durumda zaten butonu göstermiyor.
        guard settings.enabled, PlusAccess.isUnlocked else { return .result() }
        WaterData.add(ml: ml > 0 ? ml : settings.defaultCup.ml)
        IntentRefresh.all()
        return .result()
    }
}

/// Widget'ları ve Denetim Merkezi düğmesini yenile.
enum IntentRefresh {
    static func all() {
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) {
            ControlCenter.shared.reloadAllControls()
        }
    }
}
