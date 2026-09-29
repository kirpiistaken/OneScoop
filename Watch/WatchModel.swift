import Foundation
import WatchConnectivity
import WatchKit
import WidgetKit

/// Saat tarafının durumu. Telefonun ortak depolama alanına (App Group) erişemediği
/// için son bilinen durumu kendi tutuyor ve telefonla WatchConnectivity üzerinden
/// konuşuyor.
///
/// "Yes"e basınca ekran hemen güncelleniyor (telefonun cevabı beklenmiyor).
/// Telefon o an ulaşılamıyorsa komut kuyruğa giriyor ve telefon açıldığında uygulanıyor.
final class WatchModel: NSObject, ObservableObject, WCSessionDelegate {

    typealias Today = WatchDayState

    @Published private(set) var payload: WatchPayload?

    /// Saatte en son ne zaman işlem yapıldı. Telefondan bundan eski bir durum
    /// gelirse (işlemden önce gönderilmiş) yok sayılıyor.
    private var lastLocalAction: Date = .distantPast

    private let actionKey = "onescoop.watch.lastAction.v1"

    override init() {
        super.init()
        payload = WatchPayload.loadStored()
        if let saved = UserDefaults.standard.object(forKey: actionKey) as? Date {
            lastLocalAction = saved
        }
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Bugünün durumu

    /// Son bilinen durumun bugüne uyarlanmış hali.
    var today: Today {
        WatchPayload.state(payload, on: Date())
    }

    // MARK: - Su (2.0)

    struct Water {
        var enabled: Bool
        var plus: Bool
        var total: Int
        var goal: Int
        var cups: [WaterCup]

        var fraction: Double { goal > 0 ? min(1, Double(total) / Double(goal)) : 0 }
    }

    var water: Water {
        let p = payload
        let isToday = p?.dateKey == DayKey.key(for: Date())
        let kinds = p?.cupKinds ?? []
        let mls = p?.cupMls ?? []
        let cups = zip(kinds, mls).compactMap { k, ml in
            WaterCup.Kind(rawValue: k).map { WaterCup(kind: $0, ml: ml) }
        }
        return Water(
            enabled: p?.waterEnabled ?? false,
            plus: p?.plus ?? false,
            total: isToday ? (p?.waterTotal ?? 0) : 0,
            goal: p?.waterGoal ?? 2500,
            cups: cups.isEmpty ? WaterCup.defaults : cups
        )
    }

    /// Bu oturumda saatten eklenenler: geri al'da ekran hemen düzelsin diye.
    private var recentWaterAdds: [Int] = []

    func addWater(_ ml: Int) {
        guard ml > 0 else { return }
        recentWaterAdds.append(ml)
        mutateLocally { p in
            let base = p.dateKey == DayKey.key(for: Date()) ? (p.waterTotal ?? 0) : 0
            p.waterTotal = base + ml
        }
        WKInterfaceDevice.current().play(.success)
        send(.addWater, ml: ml)
    }

    func undoWater() {
        guard water.total > 0 else { return }
        if let last = recentWaterAdds.popLast() {
            mutateLocally { p in p.waterTotal = max(0, (p.waterTotal ?? 0) - last) }
        }
        WKInterfaceDevice.current().play(.click)
        send(.undoWater)
    }

    /// Mevcut durumu (su alanları dahil) koruyarak yerelde değiştir.
    private func mutateLocally(_ change: (inout WatchPayload) -> Void) {
        let now = Date()
        lastLocalAction = now
        UserDefaults.standard.set(now, forKey: actionKey)
        var p = payload ?? WatchPayload(dateKey: DayKey.key(for: now), isTaken: false, grams: 0,
                                        streak: 0, onboarded: true, updatedAt: now)
        if p.dateKey != DayKey.key(for: now) {
            // Yeni gün: dünkü kreatin ve su taşınmasın.
            let t = WatchPayload.state(p, on: now)
            p.dateKey = DayKey.key(for: now)
            p.isTaken = false
            p.streak = t.streak
            p.waterTotal = 0
        }
        change(&p)
        p.updatedAt = now
        save(p)
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
        // Su alanları korunuyor (eskiden payload baştan yazılıyordu).
        let fallbackGrams = payload?.grams ?? 0
        mutateLocally { p in
            p.isTaken = isTaken
            p.streak = streak
            p.grams = grams ?? fallbackGrams
            p.onboarded = onboarded
        }
    }

    private func send(_ action: WatchAction, ml: Int? = nil) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        let message = action.message(day: DayKey.key(for: Date()), ml: ml)

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
            p.store()
            // Saat kadranındaki göstergeyi de güncelle.
            WidgetCenter.shared.reloadAllTimelines()
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
