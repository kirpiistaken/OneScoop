import Foundation
import WatchConnectivity
import WidgetKit

/// Telefon tarafı: saatten gelen "kaydet / geri al" komutlarını uygular,
/// her değişiklikte güncel durumu saate gönderir. Sadece uygulama target'ında.
///
/// Saat komutu gönderdiğinde telefon uygulaması kapalıysa iOS onu arka planda
/// uyandırıyor; bu sınıf App.init içinde aktive edildiği için komut kaybolmuyor.
final class PhoneWatchBridge: NSObject, WCSessionDelegate {

    static let shared = PhoneWatchBridge()
    private override init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Güncel durumu saate gönderir. Saat yoksa ya da uygulama kurulu değilse sessizce geçer.
    func pushStatus() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled else { return }
        try? session.updateApplicationContext(Self.currentPayload().dictionary)
    }

    static func currentPayload() -> WatchPayload {
        let status = Persistence.currentStatus()
        let water = WaterData.loadSettings()
        return WatchPayload(
            dateKey: status.dateKey,
            isTaken: status.isTaken,
            grams: status.grams,
            streak: status.streak,
            onboarded: Persistence.loadSettings().hasCompletedOnboarding,
            updatedAt: Date(),
            waterEnabled: water.enabled,
            waterTotal: WaterData.total(),
            waterGoal: WaterData.goal(),
            cupKinds: water.cups.map(\.kind.rawValue),
            cupMls: water.cups.map(\.ml),
            plus: PlusAccess.isUnlocked
        )
    }

    // MARK: - Komutu uygula

    /// Tekrar gelse de zarar vermez: kayıtlı günü yeniden kaydetmiyor,
    /// kayıtsız günü geri almıyor.
    private func apply(_ message: [String: Any]) {
        guard let (action, day) = WatchAction.parse(message),
              let date = DayKey.date(from: day) else { return }

        switch action {
        case .log:
            if !Persistence.isTaken(on: date) { Persistence.markTaken(on: date) }
        case .undo:
            if Persistence.isTaken(on: date) { Persistence.undo(on: date) }
        case .addWater, .undoWater:
            applyWater(action, message: message, day: day)
            return
        }

        IntentRefresh.all()
        Task { @MainActor in
            CloudSync.sync()
            CreatineStore.shared.reload()
            await NotificationManager.reschedule()
        }
    }

    /// 2.0 — Saatten su. Sadece OneScoop+ ile ve sadece bugün için
    /// (dünden kalmış kuyruktaki bir komut bugüne eklenmesin).
    private func applyWater(_ action: WatchAction, message: [String: Any], day: String) {
        guard PlusAccess.isUnlocked, WaterData.loadSettings().enabled, day == DayKey.today else { return }
        switch action {
        case .addWater:
            guard let ml = WatchAction.ml(message), ml > 0 else { return }
            WaterData.add(ml: ml)
        case .undoWater:
            WaterData.removeLatestToday()
        default:
            return
        }
        IntentRefresh.all()
        Task { @MainActor in
            CreatineStore.shared.reload()
            await WaterReminders.reschedule()
            await HealthSync.pushLocalChanges()
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        pushStatus()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Kullanıcı başka bir saate geçtiyse yeniden aktive et.
        WCSession.default.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        pushStatus()
    }

    /// Saat telefona ulaşabildiğinde anlık mesaj.
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        apply(message)
        replyHandler(Self.currentPayload().dictionary)
    }

    /// Saat telefona ulaşamadığında kuyruğa alınan mesaj.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        apply(userInfo)
        pushStatus()
    }
}
