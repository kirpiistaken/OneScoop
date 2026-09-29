import Foundation

// 2.0 — Su takibi. Uygulama ve widget uzantısı ortak kullanıyor, bu yüzden
// sadece Foundation. Kreatin kaydından tamamen ayrı tutuluyor: su kapalıyken
// uygulama 1.x ile birebir aynı davranıyor.

/// Kullanıcının kendi kabı (bardak, shaker, şişe). En fazla 3 tane.
struct WaterCup: Codable, Equatable, Identifiable, Hashable {
    enum Kind: String, Codable, CaseIterable {
        case glass, shaker, bottle
    }

    var id: UUID = UUID()
    var kind: Kind
    var ml: Int

    static let defaults: [WaterCup] = [
        WaterCup(kind: .glass, ml: 250),
        WaterCup(kind: .shaker, ml: 500),
        WaterCup(kind: .bottle, ml: 750),
    ]
}

struct WaterSettings: Codable, Equatable {
    var enabled: Bool = false
    var goalMl: Int = 2500
    var cups: [WaterCup] = WaterCup.defaults
    var defaultCupID: UUID?
    /// 2.0'ın "Yeni: Su" tanıtımı bir kez gösterilsin.
    var hasSeenIntro: Bool = false

    // Hatırlatmalar (WaterReminders.swift)
    var reminderMode: WaterReminderMode = .off
    var wakeHour: Int = 8
    var sleepHour: Int = 22
    var simpleIntervalHours: Int = 2

    static let `default` = WaterSettings()

    var defaultCup: WaterCup {
        cups.first { $0.id == defaultCupID } ?? cups.first ?? WaterCup.defaults[0]
    }

    enum CodingKeys: String, CodingKey {
        case enabled, goalMl, cups, defaultCupID, hasSeenIntro
        case reminderMode, wakeHour, sleepHour, simpleIntervalHours
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = WaterSettings()
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? d.enabled
        goalMl = try c.decodeIfPresent(Int.self, forKey: .goalMl) ?? d.goalMl
        cups = try c.decodeIfPresent([WaterCup].self, forKey: .cups) ?? d.cups
        defaultCupID = try c.decodeIfPresent(UUID.self, forKey: .defaultCupID)
        hasSeenIntro = try c.decodeIfPresent(Bool.self, forKey: .hasSeenIntro) ?? d.hasSeenIntro
        reminderMode = try c.decodeIfPresent(WaterReminderMode.self, forKey: .reminderMode) ?? d.reminderMode
        wakeHour = try c.decodeIfPresent(Int.self, forKey: .wakeHour) ?? d.wakeHour
        sleepHour = try c.decodeIfPresent(Int.self, forKey: .sleepHour) ?? d.sleepHour
        simpleIntervalHours = try c.decodeIfPresent(Int.self, forKey: .simpleIntervalHours) ?? d.simpleIntervalHours
    }
}

struct WaterEntry: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var ml: Int
    var at: Date
}

/// Su verisinin okunup yazıldığı tek yer. Persistence gibi her mutasyon
/// "oku → değiştir → yaz"; widget ayrı process.
enum WaterData {
    private static let settingsKey = "ct.water.settings.v1"
    private static let logKey = "ct.water.log.v1"      // [gün: [kayıt]]

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: Ayarlar

    static func loadSettings() -> WaterSettings {
        guard let data = AppGroup.defaults.data(forKey: settingsKey),
              let s = try? decoder.decode(WaterSettings.self, from: data) else { return .default }
        return s
    }

    static func saveSettings(_ s: WaterSettings) {
        guard let data = try? encoder.encode(s) else { return }
        AppGroup.defaults.set(data, forKey: settingsKey)
    }

    // MARK: Kayıt

    static func loadLog() -> [String: [WaterEntry]] {
        guard let data = AppGroup.defaults.data(forKey: logKey),
              let log = try? decoder.decode([String: [WaterEntry]].self, from: data) else { return [:] }
        return log
    }

    private static func saveLog(_ log: [String: [WaterEntry]]) {
        guard let data = try? encoder.encode(log) else { return }
        AppGroup.defaults.set(data, forKey: logKey)
    }

    static func entries(on date: Date = Date()) -> [WaterEntry] {
        (loadLog()[DayKey.key(for: date)] ?? []).sorted { $0.at < $1.at }
    }

    static func total(on date: Date = Date()) -> Int {
        entries(on: date).reduce(0) { $0 + $1.ml }
    }

    @discardableResult
    static func add(ml: Int, at date: Date = Date()) -> WaterEntry {
        var log = loadLog()
        let entry = WaterEntry(ml: ml, at: date)
        log[DayKey.key(for: date), default: []].append(entry)
        saveLog(log)
        return entry
    }

    static func remove(_ id: UUID) {
        var log = loadLog()
        for (day, list) in log where list.contains(where: { $0.id == id }) {
            let rest = list.filter { $0.id != id }
            log[day] = rest.isEmpty ? nil : rest
        }
        saveLog(log)
    }

    /// Bugün en son girilen suyu siler (widget'taki geri al).
    static func removeLatestToday() {
        guard let last = entries().max(by: { $0.at < $1.at }) else { return }
        remove(last.id)
    }

    static func resetAll() {
        AppGroup.defaults.removeObject(forKey: logKey)
        AppGroup.defaults.removeObject(forKey: settingsKey)
    }
}

/// OneScoop+ kilidi. Uygulama satın almayı doğruluyor ve sonucu buraya
/// yazıyor; widget buradan okuyor.
enum PlusAccess {
    private static let key = "ct.plus.unlocked.v1"

    /// TASLAK: Satın alma App Store Connect'te kurulana kadar test
    /// build'lerinde her şey açık. Yayından önce `false` yapılacak.
    static let draftUnlocksEverything = true

    static var isUnlocked: Bool {
        draftUnlocksEverything || AppGroup.defaults.bool(forKey: key)
    }

    static func setPurchased(_ value: Bool) {
        AppGroup.defaults.set(value, forKey: key)
    }
}

extension Int {
    /// Yuvarlamadan, gereksiz sıfır olmadan (dile göre ayraç):
    /// 750 -> "0,75", 700 -> "0,7", 1000 -> "1", 0 -> "0"
    var litersString: String {
        (Double(self) / 1000).formatted(.number.precision(.fractionLength(0...2)))
    }
}
