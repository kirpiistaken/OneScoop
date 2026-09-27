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
        return WatchPayload(
            dateKey: status.dateKey,
            isTaken: status.isTaken,
            grams: status.grams,
            streak: status.streak,
            onboarded: Persistence.loadSettings().hasCompletedOnboarding,
            updatedAt: Date()
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
        }

        WidgetCenter.shared.reloadAllTimelines()
        Task { @MainActor in
            CloudSync.sync()
            CreatineStore.shared.reload()
            await NotificationManager.reschedule()
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
