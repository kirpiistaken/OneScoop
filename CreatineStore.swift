import Foundation
import WidgetKit

@MainActor
final class CreatineStore: ObservableObject {
    static let shared = CreatineStore()

    @Published private(set) var settings: DoseSettings
    @Published private(set) var log: [String: DoseEntry]

    private init() {
        settings = Persistence.loadSettings()
        log = Persistence.loadLog()
    }

    func reload() {
        settings = Persistence.loadSettings()
        log = Persistence.loadLog()
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
        WidgetCenter.shared.reloadAllTimelines()
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
        settings = .default
        log = [:]
        Task { await NotificationManager.cancelAll() }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func syncSideEffects() {
        WidgetCenter.shared.reloadAllTimelines()
        Task { await NotificationManager.reschedule() }
    }
}
