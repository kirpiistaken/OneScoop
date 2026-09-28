import AppIntents
import SwiftUI
import WidgetKit

/// Denetim Merkezi düğmesi (iOS 18+). Aynı düğme iPhone 15 Pro ve sonrasında
/// Eylem düğmesine de atanabiliyor.
///
/// Sadece kaydediyor, geri almıyor: Eylem düğmesine yanlışlıkla iki kez basmak
/// bugünkü kaydı silmesin. Geri alma uygulamada ve widget'ta duruyor.
///
/// Bu dosya widget uzantısı target'ında.
@available(iOS 18.0, *)
struct LogCreatineControl: ControlWidget {
    static let kind = "com.atalay.creatinetracker.LogControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind, provider: TakenTodayProvider()) { isTaken in
            ControlWidgetButton(action: MarkTakenIntent()) {
                Label(
                    isTaken ? L.widgetDoseLogged : L.shortcutLog,
                    systemImage: isTaken ? "checkmark.circle.fill" : "drop.fill"
                )
            }
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
