import Foundation

/// Günleri "2026-09-12" gibi stabil bir anahtarla saklıyoruz.
/// Böylece saat dilimi/yaz saati oynamaları kaydı bozmuyor.
enum DayKey {
    static let calendar = Calendar.current

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        formatter.date(from: key)
    }

    static var today: String { key(for: Date()) }

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func daysBetween(_ from: Date, _ to: Date) -> Int {
        calendar.dateComponents([.day], from: startOfDay(from), to: startOfDay(to)).day ?? 0
    }

    /// Sonraki gece yarısı — widget timeline'ını sıfırlamak için.
    static var nextMidnight: Date {
        calendar.date(byAdding: .day, value: 1, to: startOfDay(Date())) ?? Date().addingTimeInterval(86_400)
    }
}
