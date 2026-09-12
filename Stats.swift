import Foundation

enum Stats {

    /// Bugünden (veya bugün alınmadıysa dünden) geriye doğru kesintisiz gün sayısı.
    static func streak(log: [String: DoseEntry], from date: Date = Date()) -> Int {
        var cursor = DayKey.startOfDay(date)
        if log[DayKey.key(for: cursor)] == nil {
            guard let yesterday = DayKey.calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while log[DayKey.key(for: cursor)] != nil {
            count += 1
            guard let prev = DayKey.calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    static func entries(in month: Date, log: [String: DoseEntry]) -> [DoseEntry] {
        guard let interval = DayKey.calendar.dateInterval(of: .month, for: month) else { return [] }
        return log.values.filter { entry in
            guard let d = DayKey.date(from: entry.day) else { return false }
            return interval.contains(DayKey.startOfDay(d))
        }
    }

    static func totalGrams(_ entries: [DoseEntry]) -> Double {
        entries.reduce(0) { $0 + $1.grams }
    }

    /// Bu aydaki gün sayısı — geçmiş aylarda ayın tamamı, bu ayda bugüne kadar.
    static func trackableDays(in month: Date) -> Int {
        guard let interval = DayKey.calendar.dateInterval(of: .month, for: month),
              let range = DayKey.calendar.range(of: .day, in: .month, for: month) else { return 30 }
        let today = DayKey.startOfDay(Date())
        if interval.contains(today) {
            return DayKey.calendar.component(.day, from: today)
        }
        return today < interval.start ? 0 : range.count
    }

    /// Takvimin altında görünen kısa özet. Sağlık tavsiyesi değil, sadece kayıt özeti.
    static func insight(for month: Date, log: [String: DoseEntry], settings: DoseSettings) -> String {
        let monthEntries = entries(in: month, log: log)
        let days = monthEntries.count
        let grams = totalGrams(monthEntries)
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        let name = formatter.string(from: month)

        guard days > 0 else {
            return "No doses logged in \(name) yet. Tap Yes on the home screen once you take today's dose."
        }

        let possible = max(trackableDays(in: month), days)
        let rate = Int((Double(days) / Double(possible) * 100).rounded())
        var lines = ["\(days) of \(possible) days in \(name) — \(grams.gramString) g total, \(rate)% consistency."]

        let current = streak(log: log)
        if current >= 2 {
            lines.append("You're on a \(current)-day streak.")
        }

        if settings.usesLoadingPhase && settings.loadingDaysRemaining > 0 {
            lines.append("Loading phase: \(settings.loadingDaysRemaining) day(s) left at \(settings.loadingDose.gramString) g, then \(settings.maintenanceDose.gramString) g daily.")
        } else if current >= 28 {
            lines.append("Daily dosing over several weeks is what keeps muscle creatine stores topped up — consistency matters more than the exact time of day.")
        } else if rate < 70 {
            lines.append("Missed days are the main thing that lets stores drift back down. A reminder helps.")
        }

        return lines.joined(separator: " ")
    }
}
