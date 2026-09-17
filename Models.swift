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

    var repeatEnabled: Bool = false
    var repeatIntervalMinutes: Int = 60
    var repeatCount: Int = 2

    // YENİ: stok takibi
    var trackSupply: Bool = false
    var containerGrams: Double = 500     // kutunun tam dolu hali
    var supplyRemaining: Double = 0      // elde kalan gram

    var hasCompletedOnboarding: Bool = false

    static let `default` = DoseSettings()

    // MARK: - Codable
    // Her alan decodeIfPresent ile okunuyor: yeni alan eklendiğinde eski
    // kullanıcının kayıtlı ayarları bozulmadan açılmaya devam ediyor.

    enum CodingKeys: String, CodingKey {
        case maintenanceDose, usesLoadingPhase, loadingDose, loadingDays, startDate
        case reminderEnabled, reminderHour, reminderMinute
        case repeatEnabled, repeatIntervalMinutes, repeatCount
        case trackSupply, containerGrams, supplyRemaining
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
        trackSupply = try c.decodeIfPresent(Bool.self, forKey: .trackSupply) ?? d.trackSupply
        containerGrams = try c.decodeIfPresent(Double.self, forKey: .containerGrams) ?? d.containerGrams
        supplyRemaining = try c.decodeIfPresent(Double.self, forKey: .supplyRemaining) ?? d.supplyRemaining
        hasCompletedOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? d.hasCompletedOnboarding
    }

    // MARK: - Doz

    func isLoadingDay(_ date: Date) -> Bool {
        guard usesLoadingPhase else { return false }
        let offset = DayKey.daysBetween(startDate, date)
        return offset >= 0 && offset < loadingDays
    }

    func dose(on date: Date) -> Double {
        isLoadingDay(date) ? loadingDose : maintenanceDose
    }

    var loadingDaysRemaining: Int {
        guard usesLoadingPhase else { return 0 }
        let used = DayKey.daysBetween(startDate, Date())
        return max(0, loadingDays - used)
    }

    var reminderTimeString: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    var notificationsPerDay: Int {
        repeatEnabled ? 1 + max(0, repeatCount) : 1
    }

    var repeatIntervalString: String {
        repeatIntervalMinutes < 60
            ? "\(repeatIntervalMinutes) min"
            : "\(repeatIntervalMinutes / 60) hr"
    }

    // MARK: - Stok

    /// Kalan gramla kaç gün daha idare edilir.
    var supplyDaysLeft: Int {
        let daily = dose(on: Date())
        guard daily > 0 else { return 0 }
        return Int((supplyRemaining / daily).rounded(.down))
    }

    /// Stokun biteceği tahmini gün.
    var supplyRunOutDate: Date? {
        guard supplyRemaining > 0 else { return nil }
        return DayKey.calendar.date(byAdding: .day, value: supplyDaysLeft, to: DayKey.startOfDay(Date()))
    }

    /// 0...1 arası doluluk — ilerleme çubuğu için.
    var supplyFraction: Double {
        guard containerGrams > 0 else { return 0 }
        return min(1, max(0, supplyRemaining / containerGrams))
    }

    var supplyIsLow: Bool {
        trackSupply && supplyRemaining > 0 && supplyDaysLeft <= 7
    }

    var supplyIsEmpty: Bool {
        trackSupply && supplyRemaining <= 0
    }
}

struct DoseEntry: Codable, Equatable {
    var day: String
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

