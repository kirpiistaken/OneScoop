import Foundation
import WatchConnectivity
import WatchKit

/// Saat tarafının durumu. Telefonun ortak depolama alanına (App Group) erişemediği
/// için son bilinen durumu kendi tutuyor ve telefonla WatchConnectivity üzerinden
/// konuşuyor.
///
/// "Yes"e basınca ekran hemen güncelleniyor (telefonun cevabı beklenmiyor).
/// Telefon o an ulaşılamıyorsa komut kuyruğa giriyor ve telefon açıldığında uygulanıyor.
final class WatchModel: NSObject, ObservableObject, WCSessionDelegate {

    struct Today {
        var isTaken: Bool
        var streak: Int
        var grams: Double?
        var onboarded: Bool
    }

    @Published private(set) var payload: WatchPayload?

    /// Saatte en son ne zaman işlem yapıldı. Telefondan bundan eski bir durum
    /// gelirse (işlemden önce gönderilmiş) yok sayılıyor.
    private var lastLocalAction: Date = .distantPast

    private let storeKey = "onescoop.watch.payload.v1"
    private let actionKey = "onescoop.watch.lastAction.v1"

    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let saved = try? JSONDecoder().decode(WatchPayload.self, from: data) {
            payload = saved
        }
        if let saved = UserDefaults.standard.object(forKey: actionKey) as? Date {
            lastLocalAction = saved
        }
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Bugünün durumu

    /// Son bilinen durumu bugüne uyarlar. Gece yarısı geçtiyse ve telefondan
    /// henüz yeni durum gelmediyse de doğru görünür.
    var today: Today {
        guard let p = payload else {
            return Today(isTaken: false, streak: 0, grams: nil, onboarded: true)
        }
        let now = Date()
        let todayKey = DayKey.key(for: now)
        let yesterday = DayKey.calendar.date(byAdding: .day, value: -1, to: now).map(DayKey.key(for:))

        if p.dateKey == todayKey {
            return Today(isTaken: p.isTaken, streak: p.streak, grams: p.grams, onboarded: p.onboarded)
        }
        if p.dateKey == yesterday {
            // Dün alındıysa seri devam ediyor; alınmadıysa bitti.
            return Today(isTaken: false, streak: p.isTaken ? p.streak : 0, grams: p.grams, onboarded: p.onboarded)
        }
        return Today(isTaken: false, streak: 0, grams: p.grams, onboarded: p.onboarded)
    }

    // MARK: - Eylemler

    func log() {
        let t = today
        guard !t.isTaken else { return }
        applyLocally(isTaken: true, streak: t.streak + 1, grams: t.grams, onboarded: t.onboarded)
        WKInterfaceDevice.current().play(.success)
        send(.log)
    }

    func undo() {
        let t = today
        guard t.isTaken else { return }
        applyLocally(isTaken: false, streak: max(0, t.streak - 1), grams: t.grams, onboarded: t.onboarded)
        WKInterfaceDevice.current().play(.click)
        send(.undo)
    }

    /// Ekran öne geldiğinde: gün değişmiş olabilir, görünümü tazele.
    func refresh() {
        objectWillChange.send()
        if WCSession.isSupported() {
            receive(WCSession.default.receivedApplicationContext, force: false)
        }
    }

    private func applyLocally(isTaken: Bool, streak: Int, grams: Double?, onboarded: Bool) {
        let now = Date()
        lastLocalAction = now
        UserDefaults.standard.set(now, forKey: actionKey)
        save(WatchPayload(
            dateKey: DayKey.key(for: now),
            isTaken: isTaken,
            grams: grams ?? payload?.grams ?? 0,
            streak: streak,
            onboarded: onboarded,
            updatedAt: now
        ))
    }

    private func send(_ action: WatchAction) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        let message = action.message(day: DayKey.key(for: Date()))

        guard session.activationState == .activated else {
            session.transferUserInfo(message)
            return
        }

        if session.isReachable {
            session.sendMessage(message, replyHandler: { [weak self] reply in
                // Cevap, komut uygulandıktan SONRA üretiliyor; doğrudan kabul et.
                self?.receive(reply, force: true)
            }, errorHandler: { _ in
                session.transferUserInfo(message)
            })
        } else {
            session.transferUserInfo(message)
        }
    }

    // MARK: - Telefondan gelen durum

    private func receive(_ dictionary: [String: Any], force: Bool) {
        guard let incoming = WatchPayload(dictionary: dictionary) else { return }
        DispatchQueue.main.async {
            guard force || incoming.updatedAt >= self.lastLocalAction else { return }
            self.save(incoming)
        }
    }

    private func save(_ p: WatchPayload) {
        let apply = {
            self.payload = p
            if let data = try? JSONEncoder().encode(p) {
                UserDefaults.standard.set(data, forKey: self.storeKey)
            }
        }
        if Thread.isMainThread { apply() } else { DispatchQueue.main.async(execute: apply) }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        receive(session.receivedApplicationContext, force: false)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        receive(applicationContext, force: false)
    }
}
