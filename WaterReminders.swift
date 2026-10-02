import Foundation
import UserNotifications

// 2.0 — Su hatırlatmaları. Uygulama ve widget uzantısı ortak kullanıyor
// (widget'tan su eklenince de hatırlatmalar yeniden hesaplanmalı).
//
// iOS, uygulamanın istediği an arka planda çalışıp "şu an geride mi?" diye
// bakmasına izin vermiyor; bildirimler önceden kurulmak zorunda. Bu yüzden:
//   - Her su kaydında (ve uygulama açılınca, gece yarısı) günün kalan
//     saatleri için "o saatte hâlâ geride olursan" bildirimleri kuruluyor.
//   - O saatten önce yeterince su girilirse yeniden hesaplama bildirimi siler.
// Böylece bildirim sadece gerçekten geride kalındığında geliyor.
//
// Basit (ücretsiz): gün içinde sabit aralıklarla; hedefe ulaşınca susar.
// Akıllı (OneScoop+): son 4 haftanın kayıtlarından "normalde bu saate kadar
// ne kadar içiyorsun" eğrisi çıkarılır (medyan). Pencere her gün kayar, yani
// algoritma her gün yeni günü öğrenip en eskisini bırakır; hafta içi ve
// hafta sonu düzeni ayrı öğrenilir. Hatırlatma saatleri de kullanıcının
// genelde su içtiği saatlere göre seçilir: o saat geçtiği halde belirgin
// gerideyse hatırlatır. Yeterli veri yokken hedefe göre düz tempo.
//
// Her iki modda da kreatin hatırlatmasının 45 dk yakınına su bildirimi
// konmaz; çakışan bildirim kreatinden sonraya kaydırılır.

enum WaterReminders {
    static let prefix = "ct.water."
    static let categoryID = "CT_WATER"
    static let addActionID = "CT_WATER_ADD"

    /// Kişisel eğri için gereken en az gün sayısı.
    static let daysToLearn = 3
    private static let historyDays = 28
    private static let horizonDays = 2          // bugün + yarın
    private static let smartMaxPerDay = 4
    private static let smartMinGap: TimeInterval = 2 * 3600

    // MARK: - Öğrenilen düzen

    /// Öğrenmede sayılan günler: bugünden önceki 28 gün içinde en az 3 kayıt
    /// girilmiş ya da hedefin %30'una ulaşılmış günler. Kaydetmeyi unuttuğun
    /// günler ortalamayı aşağı çekmesin diye.
    static func learningDays(log: [String: [WaterEntry]], goal: Int, now: Date = Date()) -> [[WaterEntry]] {
        let cal = DayKey.calendar
        return (1...historyDays).compactMap { back in
            guard let day = cal.date(byAdding: .day, value: -back, to: now),
                  let list = log[DayKey.key(for: day)] else { return nil }
            let total = list.reduce(0) { $0 + $1.ml }
            return (list.count >= 3 || total >= goal * 3 / 10) ? list : nil
        }
    }

    /// Hafta içi / hafta sonu ayrı: o güne benzeyen günlerden yeterince
    /// varsa sadece onlar, yoksa hepsi.
    static func days(like day: Date, from all: [[WaterEntry]]) -> [[WaterEntry]] {
        let cal = DayKey.calendar
        let weekend = cal.isDateInWeekend(day)
        let same = all.filter { list in list.first.map { cal.isDateInWeekend($0.at) } == weekend }
        return same.count >= daysToLearn ? same : all
    }

    /// Kullanıcının genelde su içtiği yarım saatler (günün dakikası olarak).
    /// Öğrenilen günlerin en az %30'unda (en az 2 gün) su girilen dilimler.
    static func usualSlots(days: [[WaterEntry]]) -> [Int] {
        let cal = DayKey.calendar
        var counts: [Int: Int] = [:]
        for list in days {
            let slots = Set(list.map { e -> Int in
                let c = cal.dateComponents([.hour, .minute], from: e.at)
                return ((c.hour ?? 0) * 60 + (c.minute ?? 0)) / 30 * 30
            })
            for slot in slots { counts[slot, default: 0] += 1 }
        }
        let need = max(2, Int((Double(days.count) * 0.3).rounded()))
        return counts.filter { $0.value >= need }.map(\.key).sorted()
    }

    // MARK: Kreatinle çakışmama

    /// Su bildirimi kreatin bildiriminin bu kadar dakika yakınına düşmez.
    static let creatineGap = 45

    /// O gün kurulacak kreatin hatırlatmalarının saatleri (günün dakikası).
    /// Kreatin o gün zaten alındıysa hatırlatma yok, çakışma da yok.
    static func creatineTimes(on day: Date) -> [Int] {
        let s = Persistence.loadSettings()
        guard s.reminderEnabled, s.hasCompletedOnboarding,
              Persistence.loadLog()[DayKey.key(for: day)] == nil else { return [] }
        let first = s.reminderHour * 60 + s.reminderMinute
        return (0..<max(1, s.notificationsPerDay))
            .map { first + $0 * s.repeatIntervalMinutes }
            .filter { $0 < 24 * 60 }
    }

    /// Kreatin bildirimine yakın düşen saati kreatinden sonraya kaydırır.
    static func avoiding(_ minutes: Int, _ creatine: [Int]) -> Int {
        var m = minutes
        for c in creatine.sorted() where abs(m - c) < creatineGap {
            m = c + creatineGap
        }
        return m
    }

    /// Bu günlerde, günün `minutes`'ına kadar içilen miktarın medyanı.
    static func learnedExpected(atMinutes minutes: Int, days: [[WaterEntry]]) -> Int {
        let cal = DayKey.calendar
        let totals = days.map { list in
            list.filter {
                let c = cal.dateComponents([.hour, .minute], from: $0.at)
                return (c.hour ?? 0) * 60 + (c.minute ?? 0) <= minutes
            }
            .reduce(0) { $0 + $1.ml }
        }
        .sorted()
        guard !totals.isEmpty else { return 0 }
        let mid = totals.count / 2
        return totals.count % 2 == 1 ? totals[mid] : (totals[mid - 1] + totals[mid]) / 2
    }

    /// Hedefe göre düz tempo: gün başından sonuna doğrusal.
    static func linearExpected(atMinutes minutes: Int, start startHour: Int, end endHour: Int, goal: Int) -> Int {
        let start = startHour * 60, end = endHour * 60
        guard end > start, minutes > start else { return 0 }
        guard minutes < end else { return goal }
        return goal * (minutes - start) / (end - start)
    }

    /// Öğrenilen günlerde ilk ve son su saatinin medyanı → akıllı hatırlatma
    /// penceresi. Makul sınırlar içinde tutuluyor.
    static func learnedWindow(days: [[WaterEntry]]) -> (Int, Int) {
        let cal = DayKey.calendar
        func median(_ xs: [Int]) -> Int? {
            let s = xs.sorted()
            return s.isEmpty ? nil : s[s.count / 2]
        }
        let firsts = days.compactMap { $0.map(\.at).min().map { cal.component(.hour, from: $0) } }
        let lasts = days.compactMap { $0.map(\.at).max().map { cal.component(.hour, from: $0) + 1 } }
        let start = min(max(median(firsts) ?? 8, 5), 12)
        let end = max(min(median(lasts) ?? 22, 24), start + 6)
        return (start, min(end, 24))
    }

    /// Şu ana kadar "beklenen" miktar. Bugün kartındaki tempo satırı da bunu
    /// kullanıyor: Plus'ta ve yeterli veri varsa kişisel eğri, yoksa düz tempo.
    static func expected(at date: Date = Date()) -> Int {
        let s = WaterData.loadSettings()
        let c = DayKey.calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        if PlusAccess.isUnlocked {
            let all = learningDays(log: WaterData.mergedLog(), goal: s.goalMl, now: date)
            let days = Self.days(like: date, from: all)
            if days.count >= daysToLearn {
                return learnedExpected(atMinutes: minutes, days: days)
            }
        }
        // Akıllıda gün penceresi öğrenilenden, basitte kullanıcının seçtiği.
        return s.reminderMode == .simple
            ? linearExpected(atMinutes: minutes, start: s.wakeHour, end: s.sleepHour, goal: WaterData.goal(on: date))
            : linearExpected(atMinutes: minutes, start: 8, end: 22, goal: WaterData.goal(on: date))
    }

    /// Ayarlarda "öğreniliyor 1/3" göstermek için.
    static func learnedDayCount() -> Int {
        let s = WaterData.loadSettings()
        return learningDays(log: WaterData.mergedLog(), goal: s.goalMl).count
    }

    // MARK: - Planlama

    static func reschedule() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        )

        let s = WaterData.loadSettings()
        guard s.enabled, s.reminderMode != .off else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let mode: WaterReminderMode = (s.reminderMode == .smart && PlusAccess.isUnlocked) ? .smart : .simple
        let log = WaterData.mergedLog()
        let allLearned = learningDays(log: log, goal: s.goalMl)
        let cal = DayKey.calendar
        let now = Date()

        for offset in 0..<horizonDays {
            guard let day = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            let key = DayKey.key(for: day)
            // Bugün için gerçek toplam; ileriki günler sıfırdan başlıyor
            // (o gün su girildikçe yeniden hesaplanacak).
            let total = offset == 0 ? (log[key] ?? []).reduce(0) { $0 + $1.ml } : 0
            let dayGoal = WaterData.goal(on: day)
            if total >= dayGoal { continue }

            let learned = days(like: day, from: allLearned)
            let usesLearned = mode == .smart && learned.count >= daysToLearn
            let creatine = creatineTimes(on: day)

            var index = 0
            var lastFire: Date?

            func add(at requested: Int, body: String) async {
                let minutes = avoiding(requested, creatine)
                guard minutes < 24 * 60,
                      let fire = cal.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day),
                      fire > now else { return }
                let content = UNMutableNotificationContent()
                content.title = L.waterTitle
                content.body = body
                content.sound = .default
                content.interruptionLevel = .active
                content.categoryIdentifier = categoryID
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire),
                    repeats: false
                )
                try? await center.add(UNNotificationRequest(
                    identifier: "\(prefix)\(key).\(index)", content: content, trigger: trigger
                ))
                index += 1
                lastFire = fire
            }

            switch mode {
            case .off:
                break

            case .simple:
                // Uyanıştan bir aralık sonra başlayıp uykuya kadar sabit aralıklarla.
                let step = max(1, s.simpleIntervalHours) * 60
                var m = s.wakeHour * 60 + step
                while m < s.sleepHour * 60 {
                    await add(at: m, body: L.notifWaterSimple)
                    m += step
                }

            case .smart:
                // Kontrol noktaları: kullanıcının genelde su içtiği yarım
                // saatlerin 45 dk sonrası ("normalde şu an içmiş olurdun").
                // Böyle en az 2 dilim yoksa saat başları. Gün penceresi
                // öğrenilen günlerden, veri yoksa 08–22. O noktada beklenenin
                // belirgin gerisindeysen bildirim; arada en az 2 saat, günde
                // en fazla 4.
                let window = usesLearned ? learnedWindow(days: learned) : (8, 22)
                let lo = (window.0 + 1) * 60, hi = (window.1 - 1) * 60
                let slots = usesLearned
                    ? usualSlots(days: learned).map { $0 + 45 }.filter { $0 >= lo && $0 <= hi }
                    : []
                let checkpoints = slots.count >= 2
                    ? slots
                    : Array(stride(from: (window.0 + 2) * 60, through: hi, by: 60))
                for m in checkpoints where index < smartMaxPerDay {
                    let expected = usesLearned
                        ? learnedExpected(atMinutes: m, days: learned)
                        : linearExpected(atMinutes: m, start: window.0, end: window.1, goal: dayGoal)
                    let behind = expected - total
                    let at = avoiding(m, creatine)
                    let fire = cal.date(bySettingHour: min(at, 24 * 60 - 1) / 60, minute: min(at, 24 * 60 - 1) % 60, second: 0, of: day) ?? day
                    let gapOK = lastFire.map { fire.timeIntervalSince($0) >= smartMinGap } ?? true
                    if gapOK && behind >= max(250, expected / 5) {
                        let body = usesLearned
                            ? L.notifWaterSmart(expected.litersString, total.litersString)
                            : L.notifWaterPace(String(Int((Double(behind) / 50).rounded()) * 50))
                        await add(at: m, body: body)
                    }
                }
            }
        }
    }

    /// Bildirimin üstündeki "+250 ml" düğmesi (varsayılan kap).
    static func category() -> UNNotificationCategory {
        let cup = WaterData.loadSettings().defaultCup
        let add = UNNotificationAction(identifier: addActionID, title: "+\(cup.ml) ml", options: [])
        return UNNotificationCategory(identifier: categoryID, actions: [add], intentIdentifiers: [], options: [])
    }
}
