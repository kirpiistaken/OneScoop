import Foundation
import UserNotifications

enum NotificationManager {

    static let prefix = "ct.reminder."
    static let maxPending = 60
    static let maxHorizonDays = 30

    // Bildirim üzerinden işaretleme
    static let categoryID = "CT_REMINDER"
    static let logActionID = "CT_LOG"

    /// Uygulama açılışında bir kez çağır.
    static func registerCategories() {
        let log = UNNotificationAction(
            identifier: logActionID,
            title: "Log it",
            options: []          // uygulamayı açmaz, arka planda çalışır
        )
        let category = UNNotificationCategory(
            identifier: categoryID,
            actions: [log],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Her durum değişikliğinde çağır: açılış, Yes/Undo, ayar değişimi.
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

        // iOS en fazla 64 bekleyen bildirim tutuyor; günlük sayıya göre
        // kaç gün ileriye gideceğimizi kısıyoruz.
        let perDay = max(1, settings.notificationsPerDay)
        let horizon = max(1, min(maxHorizonDays, maxPending / perDay))

        for offset in 0..<horizon {
            guard let day = DayKey.calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let key = DayKey.key(for: day)
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

                guard let fireDate, fireDate > now else { continue }
                if let endOfDay, fireDate >= endOfDay { break }

                let content = UNMutableNotificationContent()
                content.title = "OneScoop"
                content.body = index == 0
                    ? "It's time to take your daily creatine!"
                    : "Still haven't logged today's creatine."
                content.sound = .default
                content.interruptionLevel = .active
                content.categoryIdentifier = categoryID   // "Log it" butonu

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: DayKey.calendar.dateComponents(
                        [.year, .month, .day, .hour, .minute], from: fireDate
                    ),
                    repeats: false
                )

                try? await center.add(
                    UNNotificationRequest(
                        identifier: "\(prefix)\(key).\(index)",
                        content: content,
                        trigger: trigger
                    )
                )
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
