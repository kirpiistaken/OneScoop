import AppIntents
import SwiftUI
import WidgetKit

/// Denetim Merkezi düğmesi (iOS 18+). Aynı düğme iPhone 15 Pro ve sonrasında
/// Eylem düğmesine de atanabiliyor.
///
/// Düz buton yerine aç/kapa (toggle): sistem dokunulduğu anda durumu kendisi
/// çeviriyor, intent'in bitmesini beklemiyor. Böylece tiksiz scoop dokunur
/// dokunmaz tikli scoop'a dönüyor. Kapatmak bugünkü kaydı geri alıyor.
///
/// Bu dosya widget uzantısı target'ında.
@available(iOS 18.0, *)
struct LogCreatineControl: ControlWidget {
    static let kind = "com.atalay.creatinetracker.LogControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind, provider: TakenTodayProvider()) { isTaken in
            ControlWidgetToggle("shortcut.log", isOn: isTaken, action: SetTakenTodayIntent()) { isOn in
                // Özel SF Symbol'ler: WidgetSymbols.xcassets (tools/make_scoop_symbol.py)
                Label(
                    isOn ? L.widgetDoseLogged : L.shortcutLog,
                    image: isOn ? "onescoop.scoop.check" : "onescoop.scoop"
                )
            }
            .tint(CT.accent)
        }
        .displayName("shortcut.log")
        .description("control.description")
    }
}

/// Düğmenin bugün alınıp alınmadığını göstermesi için.
@available(iOS 18.0, *)
struct TakenTodayProvider: ControlValueProvider {
    var previewValue: Bool { false }

    func currentValue() async throws -> Bool {
        Persistence.isTaken()
    }
}

/// Denetim Merkezi aç/kapa düğmesinin eylemi: açık = bugün alındı, kapalı = geri al.
@available(iOS 18.0, *)
struct SetTakenTodayIntent: SetValueIntent {
    static var title: LocalizedStringResource = "intent.log.title"
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    @Parameter(title: "intent.log.title")
    var value: Bool

    init() {}

    func perform() async throws -> some IntentResult {
        let taken = Persistence.isTaken()
        if value && !taken {
            Persistence.markTaken()
        } else if !value && taken {
            Persistence.undo()
        }
        await NotificationManager.reschedule()
        IntentRefresh.all()
        return .result()
    }
}
