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

    var hasCompletedOnboarding: Bool = false

    static let `default` = DoseSettings()

    /// Verilen gün loading fazına mı düşüyor?
    func isLoadingDay(_ date: Date) -> Bool {
        guard usesLoadingPhase else { return false }
        let offset = DayKey.daysBetween(startDate, date)
        return offset >= 0 && offset < loadingDays
    }

    /// O gün alınması gereken doz.
    func dose(on date: Date) -> Double {
        isLoadingDay(date) ? loadingDose : maintenanceDose
    }

    /// Loading fazının bittiği gün (dahil değil).
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
}

struct DoseEntry: Codable, Equatable {
    var day: String        // "yyyy-MM-dd"
    var grams: Double
    var takenAt: Date
}

/// Widget ve uygulamanın ortak okuduğu anlık durum.
struct DayStatus: Equatable {
    var dateKey: String
    var isTaken: Bool
    var grams: Double
    var isLoadingDay: Bool
    var streak: Int
}
