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

    private static let key = "payload"

    var dictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [Self.key: data]
    }

    init(dateKey: String, isTaken: Bool, grams: Double, streak: Int, onboarded: Bool, updatedAt: Date) {
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

    static let actionKey = "action"
    static let dayKey = "day"

    func message(day: String) -> [String: Any] {
        [Self.actionKey: rawValue, Self.dayKey: day]
    }

    static func parse(_ message: [String: Any]) -> (WatchAction, String)? {
        guard let raw = message[actionKey] as? String,
              let action = WatchAction(rawValue: raw),
              let day = message[dayKey] as? String else { return nil }
        return (action, day)
    }
}
