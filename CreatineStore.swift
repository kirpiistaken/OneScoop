import Foundation
import WidgetKit

@MainActor
final class CreatineStore: ObservableObject {
    static let shared = CreatineStore()

    @Published private(set) var settings: DoseSettings
    @Published private(set) var log: [String: DoseEntry]
    @Published private(set) var iCloudEnabled: Bool

    private init() {
        settings = Persistence.loadSettings()
        log = Persistence.loadLog()
        iCloudEnabled = CloudSync.isEnabled
    }

    func reload() {
        settings = Persistence.loadSettings()
        log = Persistence.loadLog()
    }

    /// Uygulama öne geldiğinde: widget'tan/bildirimden/saatten gelenleri al,
    /// iCloud ile birleştir, her yeri güncelle.
    func becameActive() {
        CloudSync.sync()
        reload()
        PhoneWatchBridge.shared.pushStatus()
    }

    /// iCloud'dan başka bir cihazın değişikliği geldiğinde.
    func applyRemoteChange() {
        reload()
        WidgetCenter.shared.reloadAllTimelines()
        PhoneWatchBridge.shared.pushStatus()
        Task { await NotificationManager.reschedule() }
    }

    // MARK: - Türetilmiş

    var todayDose: Double { settings.dose(on: Date()) }
    var isTodayTaken: Bool { log[DayKey.today] != nil }
    var todayEntry: DoseEntry? { log[DayKey.today] }
    var streak: Int { Stats.streak(log: log) }

    func entry(for date: Date) -> DoseEntry? { log[DayKey.key(for: date)] }

    // MARK: - Eylemler

    func markTaken(on date: Date = Date()) {
        log = Persistence.markTaken(on: date)
        settings = Persistence.loadSettings()   // stok düşmüş olabilir
        syncSideEffects()
    }

    func undo(on date: Date = Date()) {
        log = Persistence.undo(on: date)
        settings = Persistence.loadSettings()   // stok geri eklenmiş olabilir
        syncSideEffects()
    }

    func update(_ transform: (inout DoseSettings) -> Void) {
        var copy = settings
        transform(&copy)
        settings = copy
        Persistence.saveSettings(copy)
        syncSideEffects()
    }

    func restock(to grams: Double? = nil) {
        Persistence.restock(to: grams)
        settings = Persistence.loadSettings()
        syncSideEffects()
    }

    func setICloudEnabled(_ enabled: Bool) {
        CloudSync.isEnabled = enabled
        iCloudEnabled = enabled
        if enabled, CloudSync.sync() {
            applyRemoteChange()
        }
    }

    func completeOnboarding() {
        update {
            $0.hasCompletedOnboarding = true
            $0.startDate = DayKey.startOfDay(Date())
        }
        Task {
            _ = await NotificationManager.requestAuthorization()
            await NotificationManager.reschedule()
        }
    }

    func resetEverything() {
        Persistence.resetAll()
        CloudSync.sync()          // silmeyi iCloud'a ve diğer cihazlara da taşı
        reload()
        Task { await NotificationManager.cancelAll() }
        WidgetCenter.shared.reloadAllTimelines()
        PhoneWatchBridge.shared.pushStatus()
    }

    private func syncSideEffects() {
        if CloudSync.sync() { reload() }
        WidgetCenter.shared.reloadAllTimelines()
        PhoneWatchBridge.shared.pushStatus()
        Task { await NotificationManager.reschedule() }
    }
}
