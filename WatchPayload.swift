import Foundation

/// Telefon ↔ saat arasında gidip gelen durum. Hem uygulama hem saat
/// target'ında derleniyor, o yüzden sadece Foundation kullanıyor.
struct WatchPayload: Codable, Equatable {
    var dateKey: String      // "yyyy-MM-dd" — hangi gün için geçerli
    var isTaken: Bool
    var grams: Double
    var streak: Int          // Stats.streak ile aynı anlam
    var onboarded: Bool      // telefonda kurulum yapılmış mı
    var updatedAt: Date

    // 2.0 — Su. Opsiyonel: eski saat/telefon sürümleriyle uyumlu kalsın.
    var waterEnabled: Bool? = nil
    var waterTotal: Int? = nil       // dateKey günü için toplam (ml)
    var waterGoal: Int? = nil        // o günün hedefi (antrenman eki dahil)
    var cupKinds: [String]? = nil    // WaterCup.Kind rawValue
    var cupMls: [Int]? = nil
    var plus: Bool? = nil            // OneScoop+ (saatten su eklemek için)

    private static let key = "payload"

    var dictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [Self.key: data]
    }

    init(dateKey: String, isTaken: Bool, grams: Double, streak: Int, onboarded: Bool, updatedAt: Date,
         waterEnabled: Bool? = nil, waterTotal: Int? = nil, waterGoal: Int? = nil,
         cupKinds: [String]? = nil, cupMls: [Int]? = nil, plus: Bool? = nil) {
        self.waterEnabled = waterEnabled
        self.waterTotal = waterTotal
        self.waterGoal = waterGoal
        self.cupKinds = cupKinds
        self.cupMls = cupMls
        self.plus = plus
        self.dateKey = dateKey
        self.isTaken = isTaken
        self.grams = grams
        self.streak = streak
        self.onboarded = onboarded
        self.updatedAt = updatedAt
    }

    init?(dictionary: [String: Any]) {
        guard let data = dictionary[Self.key] as? Data,
              let decoded = try? JSONDecoder().decode(WatchPayload.self, from: data) else { return nil }
        self = decoded
    }
}

/// Saatten telefona giden komut.
enum WatchAction: String {
    case log, undo
    case addWater, undoWater          // 2.0

    static let actionKey = "action"
    static let dayKey = "day"
    static let mlKey = "ml"

    func message(day: String, ml: Int? = nil) -> [String: Any] {
        var m: [String: Any] = [Self.actionKey: rawValue, Self.dayKey: day]
        if let ml { m[Self.mlKey] = ml }
        return m
    }

    static func ml(_ message: [String: Any]) -> Int? {
        message[mlKey] as? Int
    }

    static func parse(_ message: [String: Any]) -> (WatchAction, String)? {
        guard let raw = message[actionKey] as? String,
              let action = WatchAction(rawValue: raw),
              let day = message[dayKey] as? String else { return nil }
        return (action, day)
    }
}

// MARK: - Saat tarafı: bugünün durumu ve saklama

/// Son bilinen durumun verilen güne uyarlanmış hali.
/// Saat uygulaması ve saat kadranı (complication) aynı hesabı kullanıyor.
struct WatchDayState: Equatable {
    var isTaken: Bool
    var streak: Int
    var grams: Double?
    var onboarded: Bool

    static let unknown = WatchDayState(isTaken: false, streak: 0, grams: nil, onboarded: true)
}

extension WatchPayload {
    /// Saat uygulaması ile kadran eklentisi arasında paylaşılan kayıt.
    static let storeKey = "onescoop.watch.payload.v1"

    static func loadStored() -> WatchPayload? {
        guard let data = AppGroup.defaults.data(forKey: storeKey) else { return nil }
        return try? JSONDecoder().decode(WatchPayload.self, from: data)
    }

    func store() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppGroup.defaults.set(data, forKey: Self.storeKey)
    }

    /// Gece yarısı geçtiyse ve telefondan henüz yeni durum gelmediyse de
    /// doğru göstermek için durumu istenen güne uyarlar.
    static func state(_ payload: WatchPayload?, on date: Date) -> WatchDayState {
        guard let p = payload else { return .unknown }
        let dayKey = DayKey.key(for: date)
        let yesterday = DayKey.calendar.date(byAdding: .day, value: -1, to: date).map(DayKey.key(for:))

        if p.dateKey == dayKey {
            return WatchDayState(isTaken: p.isTaken, streak: p.streak, grams: p.grams, onboarded: p.onboarded)
        }
        if p.dateKey == yesterday {
            // Dün alındıysa seri devam ediyor; alınmadıysa bitti.
            return WatchDayState(isTaken: false, streak: p.isTaken ? p.streak : 0, grams: p.grams, onboarded: p.onboarded)
        }
        return WatchDayState(isTaken: false, streak: 0, grams: p.grams, onboarded: p.onboarded)
    }
}
