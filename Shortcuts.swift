import AppIntents

/// Siri ve Kısayollar. Bu dosya SADECE uygulama target'ında.
///
/// Kısayol kutucuklarının başlıkları çevriliyor. Sesli komut cümleleri
/// şimdilik İngilizce: onlar ayrı bir AppShortcuts.xcstrings dosyası istiyor.
struct OneScoopShortcuts: AppShortcutsProvider {

    static var shortcutTileColor: ShortcutTileColor { .blue }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MarkTakenIntent(),
            phrases: [
                "Log my creatine in \(.applicationName)",
                "Log creatine in \(.applicationName)",
                "I took my creatine in \(.applicationName)",
                "Mark creatine as taken in \(.applicationName)",
                "\(.applicationName) creatine done"
            ],
            shortTitle: "shortcut.log",
            systemImageName: "checkmark.circle.fill"
        )

        AppShortcut(
            intent: UndoTakenIntent(),
            phrases: [
                "Undo my creatine in \(.applicationName)",
                "Remove today's creatine in \(.applicationName)"
            ],
            shortTitle: "shortcut.undo",
            systemImageName: "arrow.uturn.backward"
        )

        AppShortcut(
            intent: AddWaterIntent(),
            phrases: [
                "Log water in \(.applicationName)",
                "Add water in \(.applicationName)",
                "I drank water in \(.applicationName)",
                "Add a glass of water in \(.applicationName)"
            ],
            shortTitle: "intent.water.title",
            systemImageName: "waterbottle.fill"
        )
    }
}
