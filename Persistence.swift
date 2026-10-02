import Foundation

/// Tüm okuma/yazma buradan geçer. App, widget ve bildirim uzantısı ayrı
/// process'ler olduğu için her mutasyon "oku → değiştir → yaz" şeklinde,
/// bellekteki kopyaya güvenmeden yapılır.
///
/// iCloud senkronu için iki ek kayıt tutuluyor:
/// - tombstones: geri alınan günler ve ne zaman geri alındıkları. Başka bir
///   cihazdaki eski kaydın silinen günü geri getirmesini engeller.
/// - settings.updatedAt: ayarların en son ne zaman değiştiği. İki cihaz
///   arasında hangi ayarların geçerli olduğuna bununla karar veriliyor.
enum Persistence {
    private static let settingsKey = "ct.settings.v1"
    private static let settingsAtKey = "ct.settings.updatedAt"
    private static let logKey = "ct.log.v1"
    private static let tombKey = "ct.tombstones.v1"

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

    static var hasStoredSettings: Bool {
        AppGroup.defaults.data(forKey: settingsKey) != nil
    }

    static func saveSettings(_ settings: DoseSettings, updatedAt: Date = Date()) {
        guard let data = try? encoder.encode(settings) else { return }
        AppGroup.defaults.set(data, forKey: settingsKey)
        AppGroup.defaults.set(updatedAt, forKey: settingsAtKey)
    }

    static var settingsUpdatedAt: Date? {
        AppGroup.defaults.object(forKey: settingsAtKey) as? Date
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

    // MARK: - Tombstones

    static func loadTombstones() -> [String: Date] {
        guard let data = AppGroup.defaults.data(forKey: tombKey),
              let decoded = try? decoder.decode([String: Date].self, from: data) else {
            return [:]
        }
        return decoded
    }

    static func saveTombstones(_ tombstones: [String: Date]) {
        guard let data = try? encoder.encode(tombstones) else { return }
        AppGroup.defaults.set(data, forKey: tombKey)
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

        var tombstones = loadTombstones()
        if tombstones.removeValue(forKey: key) != nil {
            saveTombstones(tombstones)
        }

        // Stoktan düş — aynı günü ikinci kez işaretlemek iki kez düşmesin.
        if settings.trackSupply && !alreadyLogged {
            let before = settings.supplyRemaining
            settings.supplyRemaining = max(0, settings.supplyRemaining - grams)
            saveSettings(settings)
            // 2.1 — "Kutu Bitti" rozeti: kutu bu kayıtla bittiyse (widget'tan da).
            if before > 0 && settings.supplyRemaining <= 0 {
                AppGroup.defaults.set(Date(), forKey: "ct.event.containerEmptied")
            }
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

            var tombstones = loadTombstones()
            tombstones[key] = Date()
            saveTombstones(tombstones)

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

    // MARK: - Porsiyonlar (2.1, yükleme fazında bölünmüş doz)

    private static let portionsKey = "ct.portions.v1"

    /// O gün işaretlenen porsiyon sayısı. Sadece son gün tutuluyor.
    static func portions(on date: Date = Date()) -> Int {
        let dict = AppGroup.defaults.dictionary(forKey: portionsKey) as? [String: Int] ?? [:]
        return dict[DayKey.key(for: date)] ?? 0
    }

    static func setPortions(_ n: Int, on date: Date = Date()) {
        AppGroup.defaults.set([DayKey.key(for: date): max(0, n)], forKey: portionsKey)
    }

    static func isTaken(on date: Date = Date()) -> Bool {
        loadLog()[DayKey.key(for: date)] != nil
    }

    /// Her şeyi siler. Silinen her gün için tombstone bırakır ki iCloud
    /// açıkken diğer cihazlardaki kopyalar veriyi geri getirmesin.
    static func resetAll() {
        let now = Date()
        var tombstones = loadTombstones()
        for key in loadLog().keys {
            tombstones[key] = now
        }
        saveTombstones(tombstones)
        saveLog([:])
        saveSettings(.default, updatedAt: now)
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
