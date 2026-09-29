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

enum WaterReminderMode: String, Codable, CaseIterable {
    case off, simple, smart
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

    /// Apple Sağlık ile eşitleme (OneScoop+).
    var healthEnabled: Bool = false

    /// Antrenman günü hedefe ek (OneScoop+, Sağlık'tan antrenman okunarak).
    var workoutBoostEnabled: Bool = false
    var workoutBoostMl: Int = 500

    static let `default` = WaterSettings()

    var defaultCup: WaterCup {
        cups.first { $0.id == defaultCupID } ?? cups.first ?? WaterCup.defaults[0]
    }

    enum CodingKeys: String, CodingKey {
        case enabled, goalMl, cups, defaultCupID, hasSeenIntro
        case reminderMode, wakeHour, sleepHour, simpleIntervalHours
        case healthEnabled, workoutBoostEnabled, workoutBoostMl
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
        healthEnabled = try c.decodeIfPresent(Bool.self, forKey: .healthEnabled) ?? d.healthEnabled
        workoutBoostEnabled = try c.decodeIfPresent(Bool.self, forKey: .workoutBoostEnabled) ?? d.workoutBoostEnabled
        workoutBoostMl = try c.decodeIfPresent(Int.self, forKey: .workoutBoostMl) ?? d.workoutBoostMl
    }
}

struct WaterEntry: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var ml: Int
    var at: Date
    /// Apple Sağlık'tan (başka bir uygulamadan) gelen kayıt. Sadece
    /// gösterilir ve hesaba katılır; OneScoop'tan silinemez, geri alınamaz.
    var fromHealth: Bool? = nil

    var isFromHealth: Bool { fromHealth == true }
}

/// Su verisinin okunup yazıldığı tek yer. Persistence gibi her mutasyon
/// "oku → değiştir → yaz"; widget ayrı process.
enum WaterData {
    private static let settingsKey = "ct.water.settings.v1"
    private static let logKey = "ct.water.log.v1"      // [gün: [kayıt]]
    /// Apple Sağlık'taki diğer uygulamaların su kayıtları (son 180 gün).
    /// Sadece uygulama doldurur; widget kilit ekranında Sağlık'ı okuyamadığı
    /// için buradaki kopyayı kullanır.
    private static let healthKey = "ct.water.health.v1"
    /// Sağlık'a yazılmış kendi kayıtlarımızın kimlikleri.
    private static let healthSyncedKey = "ct.water.healthSynced.v1"
    /// Sağlık'ta antrenman olan günler (son 180 gün).
    private static let workoutDaysKey = "ct.water.workoutDays.v1"

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

    /// Sadece OneScoop'ta girilenler (geri alınabilenler).
    static func localEntries(on date: Date = Date()) -> [WaterEntry] {
        (loadLog()[DayKey.key(for: date)] ?? []).sorted { $0.at < $1.at }
    }

    /// Gösterilen ve hesaba katılan: OneScoop'un kayıtları + (açıksa) Sağlık'tan gelenler.
    static func entries(on date: Date = Date()) -> [WaterEntry] {
        let key = DayKey.key(for: date)
        return ((loadLog()[key] ?? []) + (healthActive ? (loadHealth()[key] ?? []) : []))
            .sorted { $0.at < $1.at }
    }

    /// Takvim ve akıllı hatırlatma için birleşik kayıt.
    static func mergedLog() -> [String: [WaterEntry]] {
        var log = loadLog()
        if healthActive {
            for (day, list) in loadHealth() { log[day, default: []].append(contentsOf: list) }
        }
        return log
    }

    private static var healthActive: Bool {
        loadSettings().healthEnabled && PlusAccess.isUnlocked
    }

    // MARK: Günün hedefi

    /// Antrenman günlerinde ek dahil hedef. Her yer (kart, widget, saat,
    /// hatırlatma, takvim) bunu kullanıyor.
    static func goal(on date: Date = Date()) -> Int {
        let s = loadSettings()
        return s.goalMl + (hasWorkoutBoost(on: date, settings: s) ? s.workoutBoostMl : 0)
    }

    static func hasWorkoutBoost(on date: Date = Date(), settings: WaterSettings? = nil) -> Bool {
        let s = settings ?? loadSettings()
        return s.workoutBoostEnabled && s.healthEnabled && PlusAccess.isUnlocked
            && workoutDays().contains(DayKey.key(for: date))
    }

    static func workoutDays() -> Set<String> {
        Set(AppGroup.defaults.stringArray(forKey: workoutDaysKey) ?? [])
    }

    static func saveWorkoutDays(_ days: Set<String>) {
        AppGroup.defaults.set(Array(days), forKey: workoutDaysKey)
    }

    // MARK: Sağlık kopyası

    static func loadHealth() -> [String: [WaterEntry]] {
        guard let data = AppGroup.defaults.data(forKey: healthKey),
              let log = try? decoder.decode([String: [WaterEntry]].self, from: data) else { return [:] }
        return log
    }

    static func saveHealth(_ log: [String: [WaterEntry]]) {
        guard let data = try? encoder.encode(log) else { return }
        AppGroup.defaults.set(data, forKey: healthKey)
    }

    static func healthSyncedIDs() -> Set<String> {
        Set(AppGroup.defaults.stringArray(forKey: healthSyncedKey) ?? [])
    }

    static func saveHealthSyncedIDs(_ ids: Set<String>) {
        AppGroup.defaults.set(Array(ids), forKey: healthSyncedKey)
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
        guard let last = localEntries().max(by: { $0.at < $1.at }) else { return }
        remove(last.id)
    }

    static func resetAll() {
        AppGroup.defaults.removeObject(forKey: logKey)
        AppGroup.defaults.removeObject(forKey: settingsKey)
        AppGroup.defaults.removeObject(forKey: healthKey)
        AppGroup.defaults.removeObject(forKey: healthSyncedKey)
        // Sağlık'a daha önce yazılmış sular orada kalır; o veri kullanıcının
        // Sağlık kaydı, oradan Sağlık uygulamasıyla silinebilir.
    }
}

/// OneScoop+ kilidi. Uygulama satın almayı doğruluyor ve sonucu buraya
/// yazıyor; widget, bildirim ve Siri buradan okuyor.
///
/// Test satın alması: TestFlight'ta gerçek ödeme olmadan satın almayı
/// denemek ve istenince geri almak için. Sadece uygulama TestFlight'tan
/// (sandbox) çalışıyorsa geçerli; App Store sürümünde hiçbir etkisi yok.
enum PlusAccess {
    private static let purchasedKey = "ct.plus.unlocked.v1"
    private static let simulatedKey = "ct.plus.simulated.v1"
    private static let testBuildKey = "ct.plus.testBuild.v1"

    static var isUnlocked: Bool {
        AppGroup.defaults.bool(forKey: purchasedKey) || isSimulated
    }

    static var isTestBuild: Bool { AppGroup.defaults.bool(forKey: testBuildKey) }
    static var isSimulated: Bool { isTestBuild && AppGroup.defaults.bool(forKey: simulatedKey) }

    static func setPurchased(_ value: Bool) { AppGroup.defaults.set(value, forKey: purchasedKey) }
    static func setSimulated(_ value: Bool) { AppGroup.defaults.set(value, forKey: simulatedKey) }
    static func setTestBuild(_ value: Bool) { AppGroup.defaults.set(value, forKey: testBuildKey) }
}

extension Int {
    /// Yuvarlamadan, gereksiz sıfır olmadan (dile göre ayraç):
    /// 750 -> "0,75", 700 -> "0,7", 1000 -> "1", 0 -> "0"
    var litersString: String {
        (Double(self) / 1000).formatted(.number.precision(.fractionLength(0...2)))
    }
}
