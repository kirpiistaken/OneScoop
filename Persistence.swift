import Foundation

/// Tüm okuma/yazma buradan geçer. App, widget ve bildirim uzantısı ayrı
/// process'ler olduğu için her mutasyon "oku → değiştir → yaz" şeklinde,
/// bellekteki kopyaya güvenmeden yapılır.
enum Persistence {
    private static let settingsKey = "ct.settings.v1"
    private static let logKey = "ct.log.v1"

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: - Settings

    static func loadSettings() -> DoseSettings {
        guard let data = AppGroup.defaults.data(forKey: settingsKey),
              let decoded = try? decoder.decode(DoseSettings.self, from: data) else {
            return .default
        }
        return decoded
    }

    static func saveSettings(_ settings: DoseSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        AppGroup.defaults.set(data, forKey: settingsKey)
    }

    // MARK: - Log

    static func loadLog() -> [String: DoseEntry] {
        guard let data = AppGroup.defaults.data(forKey: logKey),
              let decoded = try? decoder.decode([String: DoseEntry].self, from: data) else {
            return [:]
        }
        return decoded
    }

    static func saveLog(_ log: [String: DoseEntry]) {
        guard let data = try? encoder.encode(log) else { return }
        AppGroup.defaults.set(data, forKey: logKey)
    }

    // MARK: - Mutations

    @discardableResult
    static func markTaken(on date: Date = Date()) -> [String: DoseEntry] {
        var settings = loadSettings()
        var log = loadLog()
        let key = DayKey.key(for: date)

        let alreadyLogged = log[key] != nil
        let grams = settings.dose(on: date)
        log[key] = DoseEntry(day: key, grams: grams, takenAt: Date())
        saveLog(log)

        // Stoktan düş — aynı günü ikinci kez işaretlemek iki kez düşmesin.
        if settings.trackSupply && !alreadyLogged {
            settings.supplyRemaining = max(0, settings.supplyRemaining - grams)
            saveSettings(settings)
        }
        return log
    }

    @discardableResult
    static func undo(on date: Date = Date()) -> [String: DoseEntry] {
        var settings = loadSettings()
        var log = loadLog()
        let key = DayKey.key(for: date)

        if let removed = log.removeValue(forKey: key) {
            saveLog(log)
            // Stoğu geri ekle, kutu kapasitesini aşmasın.
            if settings.trackSupply {
                settings.supplyRemaining = min(
                    settings.containerGrams,
                    settings.supplyRemaining + removed.grams
                )
                saveSettings(settings)
            }
        }
        return log
    }

    /// Yeni kutu açıldı: kalanı kutu kapasitesine çıkar.
    static func restock(to grams: Double? = nil) {
        var settings = loadSettings()
        settings.supplyRemaining = grams ?? settings.containerGrams
        saveSettings(settings)
    }

    static func isTaken(on date: Date = Date()) -> Bool {
        loadLog()[DayKey.key(for: date)] != nil
    }

    static func resetAll() {
        AppGroup.defaults.removeObject(forKey: logKey)
        AppGroup.defaults.removeObject(forKey: settingsKey)
    }

    // MARK: - Widget

    static func currentStatus() -> DayStatus {
        let settings = loadSettings()
        let log = loadLog()
        let today = Date()
        return DayStatus(
            dateKey: DayKey.key(for: today),
            isTaken: log[DayKey.key(for: today)] != nil,
            grams: settings.dose(on: today),
            isLoadingDay: settings.isLoadingDay(today),
            streak: Stats.streak(log: log)
        )
    }
}
