import Foundation

// 2.1 — Rozetler (ücretsiz). Sadece uygulama target'ında.
//
// Kural: rozetler sadece "zamanında" girilen günleri sayar. Takvimden geçmiş
// bir güne sonradan eklenen kreatin rozete sayılmaz. Her kreatin kaydında
// kaydın gerçekte ne zaman girildiği (takenAt) zaten tutuluyor; gün, ertesi
// sabah 04:00'e kadar girildiyse geçerli (gece yarısını kaçıranlar için).
// Su geçmişe eklenemiyor; Apple Sağlık'tan gelen su da sayılıyor.
//
// Seri rozetleri kayıtlardan her seferinde yeniden hesaplanıyor (en uzun
// geçerli seri), yani iCloud ile kayıtlar geldikçe başka cihazda da açılıyor.
// Kazanılan rozetler tarihiyle saklanıyor ve iCloud'a da yazılıyor; seri
// sonradan bozulsa da rozet gitmiyor.

enum BadgeTier: Int, Codable, Comparable {
    case bronze, silver, gold, blue
    static func < (a: BadgeTier, b: BadgeTier) -> Bool { a.rawValue < b.rawValue }
}

enum BadgeGlyph {
    case scoop, drop, star, bolt, box, calendar
}

struct Badge: Identifiable, Equatable {
    enum Group { case creatine, water, special }

    let id: String
    let group: Group
    let tier: BadgeTier
    let glyph: BadgeGlyph
    /// Kurdeledeki yazı: "7", "30", "100%", "30/30"…
    let ribbon: String
    /// Seri rozetlerinde gereken gün; özel rozetlerde nil.
    let days: Int?

    var name: String {
        switch id {
        case "c7": L.badgeC7
        case "c30": L.badgeC30
        case "c100": L.badgeC100
        case "c365": L.badgeC365
        case "w7": L.badgeW7
        case "w30": L.badgeW30
        case "w100": L.badgeW100
        case "w365": L.badgeW365
        case "first": L.badgeFirst
        case "loading": L.badgeLoading
        case "container": L.badgeContainer
        default: L.badgeMonth
        }
    }

    var detail: String {
        switch group {
        case .creatine: return L.badgeCreatineDetail(days ?? 0)
        case .water: return L.badgeWaterDetail(days ?? 0)
        case .special: break
        }
        switch id {
        case "first": return L.badgeFirstDetail
        case "loading": return L.badgeLoadingDetail
        case "container": return L.badgeContainerDetail
        default: return L.badgeMonthDetail
        }
    }

    static let all: [Badge] = [
        Badge(id: "c7", group: .creatine, tier: .bronze, glyph: .scoop, ribbon: "7", days: 7),
        Badge(id: "c30", group: .creatine, tier: .silver, glyph: .scoop, ribbon: "30", days: 30),
        Badge(id: "c100", group: .creatine, tier: .gold, glyph: .scoop, ribbon: "100", days: 100),
        Badge(id: "c365", group: .creatine, tier: .blue, glyph: .scoop, ribbon: "365", days: 365),
        Badge(id: "w7", group: .water, tier: .bronze, glyph: .drop, ribbon: "7", days: 7),
        Badge(id: "w30", group: .water, tier: .silver, glyph: .drop, ribbon: "30", days: 30),
        Badge(id: "w100", group: .water, tier: .gold, glyph: .drop, ribbon: "100", days: 100),
        Badge(id: "w365", group: .water, tier: .blue, glyph: .drop, ribbon: "365", days: 365),
        Badge(id: "first", group: .special, tier: .bronze, glyph: .star, ribbon: "1.", days: nil),
        Badge(id: "loading", group: .special, tier: .silver, glyph: .bolt, ribbon: "", days: nil),
        Badge(id: "container", group: .special, tier: .gold, glyph: .box,
              ribbon: (1.0).formatted(.percent.precision(.fractionLength(0))), days: nil),
        Badge(id: "month", group: .special, tier: .blue, glyph: .calendar, ribbon: "", days: nil),
    ]

    static func with(id: String) -> Badge? { all.first { $0.id == id } }
}

/// Rozetlerin o anki durumu: hangileri kazanıldı, seriler nerede.
struct BadgeProgress {
    var earned: [String: Date]
    var creatineStreak: Int        // şu anki geçerli kreatin serisi
    var waterStreak: Int           // şu anki su hedefi serisi
    var loadingDays: Int           // yükleme fazının gün sayısı (kurdele için)
    var monthDays: Int             // bu ayın gün sayısı (kurdele için)

    func isEarned(_ b: Badge) -> Bool { earned[b.id] != nil }

    /// Kurdelede yazacak metin. Kilitli seri rozetinde ilerleme: "42/365".
    func ribbon(for b: Badge) -> String {
        if !isEarned(b), let days = b.days {
            let current = b.group == .creatine ? creatineStreak : waterStreak
            if current > 0 { return "\(min(current, days))/\(days)" }
        }
        switch b.id {
        case "loading": return "\(loadingDays)"
        case "month": return "\(monthDays)/\(monthDays)"
        default: return b.ribbon
        }
    }

    /// Bir sonraki kreatin/su seri rozeti ve kalan gün.
    func next(in group: Badge.Group) -> (badge: Badge, remaining: Int)? {
        let current = group == .creatine ? creatineStreak : waterStreak
        guard let b = Badge.all.first(where: { $0.group == group && !isEarned($0) }),
              let days = b.days else { return nil }
        return (b, max(0, days - current))
    }

    var earnedCount: Int { earned.count }
}

enum Badges {
    private static let earnedKey = "ct.badges.earned.v1"
    /// Persistence.markTaken'in kutu bittiğinde bıraktığı işaret (widget dahil).
    static let containerEventKey = "ct.event.containerEmptied"

    // MARK: Saklama

    static func loadEarned() -> [String: Date] {
        guard let data = AppGroup.defaults.data(forKey: earnedKey),
              let dict = try? JSONDecoder().decode([String: Date].self, from: data) else { return [:] }
        return dict
    }

    static func saveEarned(_ earned: [String: Date]) {
        guard let data = try? JSONEncoder().encode(earned) else { return }
        AppGroup.defaults.set(data, forKey: earnedKey)
    }

    // MARK: Geçerli günler

    /// Kayıt o gün (ertesi sabah 04:00'e kadar) girildiyse geçerli.
    static func isGenuine(_ entry: DoseEntry) -> Bool {
        guard let day = DayKey.date(from: entry.day),
              let deadline = DayKey.calendar.date(byAdding: .hour, value: 28, to: DayKey.startOfDay(day))
        else { return false }
        return entry.takenAt < deadline
    }

    static func genuineDays(_ log: [String: DoseEntry]) -> Set<String> {
        Set(log.values.filter(isGenuine).map(\.day))
    }

    /// Günler kümesinde en uzun ardışık seri ve bugüne (ya da düne) uzanan seri.
    static func streaks(_ days: Set<String>, today: Date = Date()) -> (best: Int, current: Int) {
        let dates = days.compactMap(DayKey.date(from:)).map(DayKey.startOfDay).sorted()
        var best = 0, run = 0
        var prev: Date?
        for d in dates {
            if let p = prev, DayKey.daysBetween(p, d) == 1 { run += 1 } else { run = 1 }
            best = max(best, run)
            prev = d
        }
        // Şu anki: bugünden (bugün yoksa dünden) geriye.
        let cal = DayKey.calendar
        var cursor = DayKey.startOfDay(today)
        if !days.contains(DayKey.key(for: cursor)) {
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var current = 0
        while days.contains(DayKey.key(for: cursor)) {
            current += 1
            guard let p = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = p
        }
        return (best, current)
    }

    /// Su hedefine ulaşılan günler (Sağlık'tan gelenler dahil).
    static func waterGoalDays() -> Set<String> {
        let log = WaterData.mergedLog()
        var out = Set<String>()
        for (key, list) in log {
            guard let day = DayKey.date(from: key) else { continue }
            let total = list.reduce(0) { $0 + $1.ml }
            if total > 0, total >= WaterData.goal(on: day) { out.insert(key) }
        }
        return out
    }

    // MARK: Değerlendirme

    /// Kayıtlara bakıp yeni kazanılan rozetleri kaydeder ve döndürür.
    @discardableResult
    static func evaluate(now: Date = Date()) -> (progress: BadgeProgress, new: [Badge]) {
        let settings = Persistence.loadSettings()
        let log = Persistence.loadLog()
        let genuine = genuineDays(log)
        let creatine = streaks(genuine, today: now)
        let water = streaks(waterGoalDays(), today: now)

        var earned = loadEarned()
        var qualifies: [String] = []

        for b in Badge.all {
            guard let days = b.days else { continue }
            let best = b.group == .creatine ? creatine.best : water.best
            if best >= days { qualifies.append(b.id) }
        }
        if !genuine.isEmpty { qualifies.append("first") }
        if loadingCompleted(settings: settings, genuine: genuine, now: now) { qualifies.append("loading") }
        if AppGroup.defaults.object(forKey: containerEventKey) != nil { qualifies.append("container") }
        if hasPerfectMonth(genuine, now: now) { qualifies.append("month") }

        var new: [Badge] = []
        for id in qualifies where earned[id] == nil {
            earned[id] = now
            if let b = Badge.with(id: id) { new.append(b) }
        }
        if !new.isEmpty { saveEarned(earned) }

        let monthDays = DayKey.calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let progress = BadgeProgress(
            earned: earned,
            creatineStreak: creatine.current,
            waterStreak: water.current,
            loadingDays: settings.loadingDays,
            monthDays: monthDays
        )
        return (progress, new)
    }

    /// Yükleme fazının her günü zamanında girildi ve faz bitti.
    private static func loadingCompleted(settings: DoseSettings, genuine: Set<String>, now: Date) -> Bool {
        guard settings.usesLoadingPhase else { return false }
        let cal = DayKey.calendar
        let start = DayKey.startOfDay(settings.startDate)
        guard let lastDay = cal.date(byAdding: .day, value: settings.loadingDays - 1, to: start),
              DayKey.startOfDay(now) >= lastDay else { return false }
        return (0..<settings.loadingDays).allSatisfy { i in
            guard let d = cal.date(byAdding: .day, value: i, to: start) else { return false }
            return genuine.contains(DayKey.key(for: d))
        }
    }

    /// Ayın her günü zamanında girilmiş bir ay var mı (bu ay, son günüyse dahil).
    private static func hasPerfectMonth(_ genuine: Set<String>, now: Date) -> Bool {
        let cal = DayKey.calendar
        var months = Set<Date>()
        for key in genuine {
            guard let d = DayKey.date(from: key),
                  let m = cal.dateInterval(of: .month, for: d)?.start else { continue }
            months.insert(m)
        }
        let today = DayKey.startOfDay(now)
        for m in months {
            guard let range = cal.range(of: .day, in: .month, for: m),
                  let last = cal.date(byAdding: .day, value: range.count - 1, to: m),
                  last <= today else { continue }
            let full = (0..<range.count).allSatisfy { i in
                guard let d = cal.date(byAdding: .day, value: i, to: m) else { return false }
                return genuine.contains(DayKey.key(for: d))
            }
            if full { return true }
        }
        return false
    }

    // MARK: iCloud

    /// İki cihazın kazanılmış rozetleri birleşir; tarih olarak en erkeni kalır.
    static func merge(_ a: [String: Date], _ b: [String: Date]) -> [String: Date] {
        var out = a
        for (id, date) in b { out[id] = min(out[id] ?? date, date) }
        return out
    }
}
