import Foundation

struct DoseSettings: Codable, Equatable {
    var maintenanceDose: Double = 5      // g/gün
    var usesLoadingPhase: Bool = false
    var loadingDose: Double = 20         // g/gün
    var loadingDays: Int = 7
    var startDate: Date = Date()

    var reminderEnabled: Bool = true
    var reminderHour: Int = 18
    var reminderMinute: Int = 0

    // YENİ: ilk bildirimden sonra tekrar hatırlatma
    var repeatEnabled: Bool = false
    var repeatIntervalMinutes: Int = 60  // 15 / 30 / 60 / 120
    var repeatCount: Int = 2             // ilk bildirimden sonra kaç kez daha

    var hasCompletedOnboarding: Bool = false

    static let `default` = DoseSettings()

    // MARK: - Codable
    // Her alanı decodeIfPresent ile okuyoruz. Böylece yeni bir alan eklendiğinde
    // eski kullanıcının kayıtlı ayarları çözümlenmeye devam eder; aksi halde
    // decode patlar ve kullanıcı kurulum ekranına geri döner.

    enum CodingKeys: String, CodingKey {
        case maintenanceDose, usesLoadingPhase, loadingDose, loadingDays, startDate
        case reminderEnabled, reminderHour, reminderMinute
        case repeatEnabled, repeatIntervalMinutes, repeatCount
        case hasCompletedOnboarding
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = DoseSettings()
        maintenanceDose = try c.decodeIfPresent(Double.self, forKey: .maintenanceDose) ?? d.maintenanceDose
        usesLoadingPhase = try c.decodeIfPresent(Bool.self, forKey: .usesLoadingPhase) ?? d.usesLoadingPhase
        loadingDose = try c.decodeIfPresent(Double.self, forKey: .loadingDose) ?? d.loadingDose
        loadingDays = try c.decodeIfPresent(Int.self, forKey: .loadingDays) ?? d.loadingDays
        startDate = try c.decodeIfPresent(Date.self, forKey: .startDate) ?? d.startDate
        reminderEnabled = try c.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? d.reminderEnabled
        reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour) ?? d.reminderHour
        reminderMinute = try c.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? d.reminderMinute
        repeatEnabled = try c.decodeIfPresent(Bool.self, forKey: .repeatEnabled) ?? d.repeatEnabled
        repeatIntervalMinutes = try c.decodeIfPresent(Int.self, forKey: .repeatIntervalMinutes) ?? d.repeatIntervalMinutes
        repeatCount = try c.decodeIfPresent(Int.self, forKey: .repeatCount) ?? d.repeatCount
        hasCompletedOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? d.hasCompletedOnboarding
    }

    // MARK: - Türetilmiş

    func isLoadingDay(_ date: Date) -> Bool {
        guard usesLoadingPhase else { return false }
        let offset = DayKey.daysBetween(startDate, date)
        return offset >= 0 && offset < loadingDays
    }

    func dose(on date: Date) -> Double {
        isLoadingDay(date) ? loadingDose : maintenanceDose
    }

    var loadingEndDate: Date? {
        guard usesLoadingPhase else { return nil }
        return DayKey.calendar.date(byAdding: .day, value: loadingDays, to: DayKey.startOfDay(startDate))
    }

    var loadingDaysRemaining: Int {
        guard usesLoadingPhase else { return 0 }
        let used = DayKey.daysBetween(startDate, Date())
        return max(0, loadingDays - used)
    }

    var reminderTimeString: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    /// Bir gün içinde kurulacak bildirim sayısı (ilk + tekrarlar).
    var notificationsPerDay: Int {
        repeatEnabled ? 1 + max(0, repeatCount) : 1
    }

    var repeatIntervalString: String {
        repeatIntervalMinutes < 60
            ? "\(repeatIntervalMinutes) min"
            : "\(repeatIntervalMinutes / 60) hr"
    }
}

struct DoseEntry: Codable, Equatable {
    var day: String        // "yyyy-MM-dd"
    var grams: Double
    var takenAt: Date
}

struct DayStatus: Equatable {
    var dateKey: String
    var isTaken: Bool
    var grams: Double
    var isLoadingDay: Bool
    var streak: Int
}
