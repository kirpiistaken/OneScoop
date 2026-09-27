import Foundation

enum Stats {

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

    static func trackableDays(in month: Date) -> Int {
        guard let interval = DayKey.calendar.dateInterval(of: .month, for: month),
              let range = DayKey.calendar.range(of: .day, in: .month, for: month) else { return 30 }
        let today = DayKey.startOfDay(Date())
        if interval.contains(today) {
            return DayKey.calendar.component(.day, from: today)
        }
        return today < interval.start ? 0 : range.count
    }

    /// Takvimin altındaki kısa özet. Cihaz diline göre çevrilir.
    static func insight(for month: Date, log: [String: DoseEntry], settings: DoseSettings) -> String {
        let monthEntries = entries(in: month, log: log)
        let days = monthEntries.count
        let grams = totalGrams(monthEntries)

        // Ay adı cihazın dilinde: "September", "Eylül", "septiembre"...
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("LLLL")
        let name = formatter.string(from: month)

        guard days > 0 else { return L.insightEmpty(name) }

        let possible = max(trackableDays(in: month), days)
        // Yüzde işareti dile göre biçimlenir: "94%", "%94", "94 %"
        let rate = (Double(days) / Double(possible)).formatted(.percent.precision(.fractionLength(0)))

        var lines = [L.insightSummary(days, possible, name, grams.gramString, rate)]

        let current = streak(log: log)
        if current >= 2 {
            lines.append(L.insightStreak(current))
        }

        if settings.usesLoadingPhase && settings.loadingDaysRemaining > 0 {
            lines.append(L.insightLoading(
                settings.loadingDaysRemaining,
                settings.loadingDose.gramString,
                settings.maintenanceDose.gramString
            ))
        } else if current >= 28 {
            lines.append(L.insightConsistent)
        } else if Double(days) / Double(possible) < 0.7 {
            lines.append(L.insightMissed)
        }

        return lines.joined(separator: " ")
    }
}

extension DoseSettings {
    /// Hatırlatma saati cihazın saat biçiminde: "18:00" ya da "6:00 PM".
    var reminderTimeLocalized: String {
        let date = Calendar.current.date(
            from: DateComponents(hour: reminderHour, minute: reminderMinute)
        ) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
