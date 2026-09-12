import Foundation
import UserNotifications

/// Tekrarlayan tek bir bildirim yerine önümüzdeki 30 gün için ayrı ayrı
/// bildirim kuruyoruz. Böylece "bugün zaten aldı" durumunda sadece o günün
/// bildirimini iptal edebiliyoruz. (iOS sınırı 64 bekleyen bildirim.)
enum NotificationManager {

    static let prefix = "ct.reminder."
    static let horizonDays = 30

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

        for offset in 0..<horizonDays {
            guard let day = DayKey.calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let key = DayKey.key(for: day)

            // O gün zaten işaretlenmişse bildirim kurma.
            if log[key] != nil { continue }

            var comps = DayKey.calendar.dateComponents([.year, .month, .day], from: day)
            comps.hour = settings.reminderHour
            comps.minute = settings.reminderMinute
            guard let fireDate = DayKey.calendar.date(from: comps), fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Creatine"
            content.body = "It's time to take your daily creatine!"
            content.sound = .default
            content.interruptionLevel = .active

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DayKey.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: prefix + key,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
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
