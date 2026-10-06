import Foundation
import WatchConnectivity
import WatchKit
import WidgetKit

/// Saat tarafının durumu. Telefonun ortak depolama alanına (App Group) erişemediği
/// için son bilinen durumu kendi tutuyor ve telefonla WatchConnectivity üzerinden
/// konuşuyor.
///
/// 2.2 — İki katman:
/// - base: telefondan gelen son durum (telefonun gerçeği)
/// - pending: saatte yapılıp telefonun henüz işlemediği komutlar
/// Ekranda base'in üstüne pending uygulanmış hali görünüyor (payload). Böylece
/// saatin elindeki durum eskiyse (ör. sabah telefondan eklenen su henüz gelmemişse)
/// saatten eklenen su eski toplamın yerine geçmiyor; telefonun durumu geldiğinde
/// toplam doğru oluyor. Telefon bir komutu işleyince kimliğini geri gönderiyor ve
/// komut pending'den düşüyor.
final class WatchModel: NSObject, ObservableObject, WCSessionDelegate {

    typealias Today = WatchDayState

    /// Ekranda görünen durum: base + bekleyen komutlar.
    @Published private(set) var payload: WatchPayload?

    private var base: WatchPayload?
    private var pending: [Pending] = []

    struct Pending: Codable {
        var id: String
        var action: String
        var day: String
        var ml: Int?
        var at: Date
    }

    private let baseKey = "onescoop.watch.base.v1"
    private let pendingKey = "onescoop.watch.pending.v1"

    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: baseKey),
           let b = try? JSONDecoder().decode(WatchPayload.self, from: data) {
            base = b
        } else {
            base = WatchPayload.loadStored()
        }
        if let data = UserDefaults.standard.data(forKey: pendingKey),
           let p = try? JSONDecoder().decode([Pending].self, from: data) {
            pending = p
        }
        recompute()
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

    func addWater(_ ml: Int) {
        guard ml > 0 else { return }
        enqueue(.addWater, ml: ml)
        WKInterfaceDevice.current().play(.success)
    }

    func undoWater() {
        guard water.total > 0 else { return }
        enqueue(.undoWater)
        WKInterfaceDevice.current().play(.click)
    }

    // MARK: - Eylemler

    func log() {
        guard !today.isTaken else { return }
        enqueue(.log)
        WKInterfaceDevice.current().play(.success)
    }

    func undo() {
        guard today.isTaken else { return }
        enqueue(.undo)
        WKInterfaceDevice.current().play(.click)
    }

    /// Ekran öne geldiğinde: gün değişmiş olabilir, görünümü tazele ve
    /// telefondan güncel durumu iste (telefon uygulaması kapalıysa da uyanıyor).
    func refresh() {
        dropStalePending()
        recompute()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        receive(session.receivedApplicationContext)
        requestSync()
    }

    // MARK: - Bekleyen komutlar

    private func enqueue(_ action: WatchAction, ml: Int? = nil) {
        let item = Pending(id: UUID().uuidString, action: action.rawValue,
                           day: DayKey.key(for: Date()), ml: ml, at: Date())
        pending.append(item)
        savePending()
        recompute()
        send(item)
    }

    /// Dünden kalan komutlar artık bugünü etkilemiyor.
    private func dropStalePending() {
        let today = DayKey.key(for: Date())
        let before = pending.count
        pending.removeAll { $0.day != today }
        if pending.count != before { savePending() }
    }

    private func savePending() {
        if let data = try? JSONEncoder().encode(pending) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
    }

    /// base'i bugüne uyarla ve bekleyen komutları üstüne uygula.
    private func recompute() {
        let now = Date()
        let todayKey = DayKey.key(for: now)
        let todays = pending.filter { $0.day == todayKey }

        guard base != nil || !todays.isEmpty else {
            publish(nil)
            return
        }
        var p = base ?? WatchPayload(dateKey: todayKey, isTaken: false, grams: 0,
                                     streak: 0, onboarded: true, updatedAt: now)
        if p.dateKey != todayKey {
            // Yeni gün: dünkü kreatin ve su taşınmasın.
            let t = WatchPayload.state(p, on: now)
            p.dateKey = todayKey
            p.isTaken = false
            p.streak = t.streak
            p.waterTotal = 0
            p.lastWaterMl = nil
        }

        var adds: [Int] = []
        var lastFromPhone = p.lastWaterMl
        for item in todays {
            switch WatchAction(rawValue: item.action) {
            case .log?:
                if !p.isTaken { p.isTaken = true; p.streak += 1 }
            case .undo?:
                if p.isTaken { p.isTaken = false; p.streak = max(0, p.streak - 1) }
            case .addWater?:
                let ml = item.ml ?? 0
                p.waterTotal = (p.waterTotal ?? 0) + ml
                adds.append(ml)
            case .undoWater?:
                // Telefon "bugünün en son kaydını" siliyor: önce saatten eklenen
                // (henüz telefona ulaşmamış) su, yoksa telefondaki son kayıt.
                if let ml = adds.popLast() {
                    p.waterTotal = max(0, (p.waterTotal ?? 0) - ml)
                } else if let ml = lastFromPhone {
                    p.waterTotal = max(0, (p.waterTotal ?? 0) - ml)
                    lastFromPhone = nil   // ondan öncekini bilmiyoruz; telefon düzeltecek
                }
            case nil:
                break
            }
        }
        publish(p)
    }

    private func publish(_ p: WatchPayload?) {
        let apply = {
            self.payload = p
            p?.store()   // saat kadranı bunu okuyor
            WidgetCenter.shared.reloadAllTimelines()
        }
        if Thread.isMainThread { apply() } else { DispatchQueue.main.async(execute: apply) }
    }

    // MARK: - Telefona gönder

    private func send(_ item: Pending) {
        guard WCSession.isSupported(), let action = WatchAction(rawValue: item.action) else { return }
        let session = WCSession.default
        let message = action.message(day: item.day, ml: item.ml, id: item.id)

        guard session.activationState == .activated else {
            session.transferUserInfo(message)
            return
        }
        if session.isReachable {
            session.sendMessage(message, replyHandler: { [weak self] reply in
                self?.receive(reply)
            }, errorHandler: { _ in
                // Anlık mesaj ulaşmadı: kuyruğa al. Telefon kimlikten tanıyıp
                // iki kez uygulamıyor.
                session.transferUserInfo(message)
            })
        } else {
            session.transferUserInfo(message)
        }
    }

    /// Telefondan güncel durumu iste. Ulaşılamıyorsa applicationContext bekleniyor.
    private func requestSync() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }
        session.sendMessage(WatchAction.syncMessage, replyHandler: { [weak self] reply in
            self?.receive(reply)
        }, errorHandler: nil)
    }

    // MARK: - Telefondan gelen durum

    private func receive(_ dictionary: [String: Any]) {
        guard let incoming = WatchPayload(dictionary: dictionary) else { return }
        DispatchQueue.main.async {
            // Telefonun kendi sırası: daha eski bir durum yenisinin yerine geçmesin.
            if let b = self.base, incoming.updatedAt < b.updatedAt { return }
            self.base = incoming
            if let data = try? JSONEncoder().encode(incoming) {
                UserDefaults.standard.set(data, forKey: self.baseKey)
            }
            // Telefonun işlediği komutlar artık base'in içinde.
            if let applied = incoming.appliedIds {
                let set = Set(applied)
                self.pending.removeAll { set.contains($0.id) }
            } else {
                // Eski telefon sürümü kimlik göndermiyor: durumdan önceki komutlar işlenmiş say.
                self.pending.removeAll { $0.at <= incoming.updatedAt }
            }
            self.savePending()
            self.dropStalePending()
            self.recompute()
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        receive(session.receivedApplicationContext)
        requestSync()
        // Önceki açılışta gönderilemeyip bekleyenler varsa tekrar dene
        // (telefon aynı kimliği iki kez uygulamıyor).
        guard session.isReachable else { return }   // kuyruktakiler zaten yolda
        DispatchQueue.main.async {
            for item in self.pending { self.send(item) }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        receive(applicationContext)
    }
}
