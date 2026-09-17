import AppIntents

/// Siri ve Kısayollar. MarkTakenIntent / UndoTakenIntent zaten widget için
/// yazılmıştı; burada sadece sesli komut cümlelerini tanımlıyoruz.
///
/// Bu dosya SADECE uygulama target'ına eklenmeli, widget'a değil.
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
            shortTitle: "Log creatine",
            systemImageName: "checkmark.circle.fill"
        )

        AppShortcut(
            intent: UndoTakenIntent(),
            phrases: [
                "Undo my creatine in \(.applicationName)",
                "Remove today's creatine in \(.applicationName)"
            ],
            shortTitle: "Undo today",
            systemImageName: "arrow.uturn.backward"
        )
    }
}
