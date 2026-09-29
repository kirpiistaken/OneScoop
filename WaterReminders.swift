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
// Akıllı (OneScoop+): son 14 günün kayıtlarından her saat için "normalde bu
// saate kadar ne kadar içiyorsun" eğrisi çıkarılır (medyan). O saatte bunun
// belirgin gerisindeysen hatırlatır. Yeterli veri yokken hedefe göre düz tempo.

enum WaterReminderMode: String, Codable, CaseIterable {
    case off, simple, smart
}

enum WaterReminders {
    static let prefix = "ct.water."
    static let categoryID = "CT_WATER"
    static let addActionID = "CT_WATER_ADD"

    /// Kişisel eğri için gereken en az gün sayısı.
    static let daysToLearn = 3
    private static let historyDays = 14
    private static let horizonDays = 2          // bugün + yarın
    private static let smartMaxPerDay = 4
    private static let smartMinGap: TimeInterval = 2 * 3600

    // MARK: - Öğrenilen düzen

    /// Öğrenmede sayılan günler: bugünden önceki 14 gün içinde en az 3 kayıt
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

    /// Hedefe göre düz tempo: uyanıştan uykuya doğrusal.
    static func linearExpected(atMinutes minutes: Int, settings s: WaterSettings) -> Int {
        let start = s.wakeHour * 60, end = s.sleepHour * 60
        guard end > start, minutes > start else { return 0 }
        guard minutes < end else { return s.goalMl }
        return s.goalMl * (minutes - start) / (end - start)
    }

    /// Şu ana kadar "beklenen" miktar. Bugün kartındaki tempo satırı da bunu
    /// kullanıyor: Plus'ta ve yeterli veri varsa kişisel eğri, yoksa düz tempo.
    static func expected(at date: Date = Date()) -> Int {
        let s = WaterData.loadSettings()
        let c = DayKey.calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        if PlusAccess.isUnlocked {
            let days = learningDays(log: WaterData.loadLog(), goal: s.goalMl, now: date)
            if days.count >= daysToLearn {
                return learnedExpected(atMinutes: minutes, days: days)
            }
        }
        return linearExpected(atMinutes: minutes, settings: s)
    }

    /// Ayarlarda "öğreniliyor 1/3" göstermek için.
    static func learnedDayCount() -> Int {
        let s = WaterData.loadSettings()
        return learningDays(log: WaterData.loadLog(), goal: s.goalMl).count
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
        let log = WaterData.loadLog()
        let learned = learningDays(log: log, goal: s.goalMl)
        let usesLearned = mode == .smart && learned.count >= daysToLearn
        let cal = DayKey.calendar
        let now = Date()

        for offset in 0..<horizonDays {
            guard let day = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            let key = DayKey.key(for: day)
            // Bugün için gerçek toplam; ileriki günler sıfırdan başlıyor
            // (o gün su girildikçe yeniden hesaplanacak).
            let total = offset == 0 ? (log[key] ?? []).reduce(0) { $0 + $1.ml } : 0
            if total >= s.goalMl { continue }

            var index = 0
            var lastFire: Date?

            func add(at minutes: Int, body: String) async {
                guard let fire = cal.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day),
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
                // Her saat başı kontrol noktası (uyanış+2 ile uyku-1 arası).
                // O saatte beklenenin belirgin gerisindeysen bildirim; arada
                // en az 2 saat, günde en fazla 4.
                var m = (s.wakeHour + 2) * 60
                while m <= (s.sleepHour - 1) * 60 && index < smartMaxPerDay {
                    let expected = usesLearned
                        ? learnedExpected(atMinutes: m, days: learned)
                        : linearExpected(atMinutes: m, settings: s)
                    let behind = expected - total
                    let fire = cal.date(bySettingHour: m / 60, minute: 0, second: 0, of: day) ?? day
                    let gapOK = lastFire.map { fire.timeIntervalSince($0) >= smartMinGap } ?? true
                    if gapOK && behind >= max(250, expected / 5) {
                        let body = usesLearned
                            ? L.notifWaterSmart(expected.litersString, total.litersString)
                            : L.notifWaterPace(String(behind))
                        await add(at: m, body: body)
                    }
                    m += 60
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
