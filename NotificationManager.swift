import Foundation
import UserNotifications

/// Her gün için ayrı bildirim kuruyoruz; böylece "bugün zaten aldı" durumunda
/// sadece o günün bildirimlerini atlayabiliyoruz.
///
/// Tekrar hatırlatma açıkken bir gün için birden fazla bildirim kuruluyor.
/// iOS aynı anda en fazla 64 bekleyen bildirim tuttuğu için kaç gün ileriye
/// gideceğimizi günlük bildirim sayısına göre hesaplıyoruz.
enum NotificationManager {

    static let prefix = "ct.reminder."
    static let maxPending = 60          // 64'ün biraz altında kalıyoruz
    static let maxHorizonDays = 30

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Her durum değişikliğinde çağır: uygulama açılışı, Yes/Undo, ayar değişimi.
    static func reschedule() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        )

        let settings = Persistence.loadSettings()
        guard settings.reminderEnabled, settings.hasCompletedOnboarding else { return }

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        let log = Persistence.loadLog()
        let now = Date()

        // Günlük bildirim sayısına göre kaç gün ileriye gideceğimizi belirle.
        let perDay = max(1, settings.notificationsPerDay)
        let horizon = max(1, min(maxHorizonDays, maxPending / perDay))

        for offset in 0..<horizon {
            guard let day = DayKey.calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let key = DayKey.key(for: day)

            // O gün zaten işaretlenmişse hiç bildirim kurma.
            if log[key] != nil { continue }

            var comps = DayKey.calendar.dateComponents([.year, .month, .day], from: day)
            comps.hour = settings.reminderHour
            comps.minute = settings.reminderMinute
            guard let first = DayKey.calendar.date(from: comps) else { continue }

            let endOfDay = DayKey.calendar.date(byAdding: .day, value: 1, to: DayKey.startOfDay(day))

            for index in 0..<perDay {
                let fireDate = index == 0
                    ? first
                    : DayKey.calendar.date(
                        byAdding: .minute,
                        value: index * settings.repeatIntervalMinutes,
                        to: first
                      )

                guard let fireDate else { continue }
                guard fireDate > now else { continue }
                // Tekrarlar gece yarısını aşmasın; ertesi güne sarkmasın.
                if let endOfDay, fireDate >= endOfDay { break }

                let content = UNMutableNotificationContent()
                content.title = "OneScoop"
                content.body = index == 0
                    ? "It's time to take your daily creatine!"
                    : "Still haven't logged today's creatine."
                content.sound = .default
                content.interruptionLevel = .active

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: DayKey.calendar.dateComponents(
                        [.year, .month, .day, .hour, .minute], from: fireDate
                    ),
                    repeats: false
                )

                let request = UNNotificationRequest(
                    identifier: "\(prefix)\(key).\(index)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }

    static func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        )
    }
}
