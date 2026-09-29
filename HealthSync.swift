import Foundation
import HealthKit

// 2.0 — Apple Sağlık ile su eşitlemesi (OneScoop+). Sadece uygulama target'ında.
//
// Yazma: OneScoop'ta girilen her su Sağlık'a "Su" örneği olarak yazılır;
// geri alınınca oradan da silinir. Widget, Denetim Merkezi ve Siri'den girilen
// sular uygulama bir sonraki açıldığında yazılır (widget Sağlık'a erişemiyor).
// Hangi kaydın yazıldığı kimlikleriyle tutuluyor: eksik olan yazılır, artık
// OneScoop'ta olmayan silinir. Böylece nereden eklenip silinirse silinsin
// Sağlık ile OneScoop aynı kalıyor.
//
// Okuma: Sağlık'taki başka uygulamaların (ve Apple Watch'un) su kayıtları
// son 180 gün için okunup App Group'a kopyalanıyor. Kendi yazdıklarımız
// atlanıyor ki aynı su iki kez sayılmasın. Bu kopya bugünkü toplamda,
// takvimde, widget'ta ve akıllı hatırlatmada kullanılıyor.

enum HealthSync {
    private static let store = HKHealthStore()
    private static let waterType = HKQuantityType(.dietaryWater)
    private static let ml = HKUnit.literUnit(with: .milli)
    private static let readDays = 180

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Açık mı: cihaz destekliyor + kullanıcı açtı + OneScoop+.
    static var isActive: Bool {
        isAvailable && WaterData.loadSettings().healthEnabled && PlusAccess.isUnlocked
    }

    /// İzin penceresi. Kullanıcı okuma iznini vermese bile iOS bunu bize
    /// söylemiyor (gizlilik); o durumda okuma boş döner, sorun olmaz.
    static func requestAccess() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [waterType], read: [waterType])
            return true
        } catch {
            return false
        }
    }

    /// Uygulama açılınca ve her su değişikliğinde.
    static func syncAll() async {
        guard isActive else { return }
        await pushLocalChanges()
        await refreshFromHealth()
    }

    // MARK: - Yazma

    static func pushLocalChanges() async {
        guard isActive else { return }
        let log = WaterData.loadLog()
        let local = log.values.flatMap { $0 }
        let localIDs = Set(local.map(\.id.uuidString))
        var synced = WaterData.healthSyncedIDs()

        // Sağlık'a henüz yazılmamış olanlar (son 30 gün; daha eskisini
        // geriye dönük doldurmuyoruz).
        let cutoff = Date().addingTimeInterval(-30 * 86_400)
        for entry in local where entry.at > cutoff && !synced.contains(entry.id.uuidString) {
            if await save(entry) { synced.insert(entry.id.uuidString) }
        }

        // OneScoop'tan silinmiş ama Sağlık'ta duranlar.
        for id in synced.subtracting(localIDs) {
            await delete(syncID: id)
            synced.remove(id)
        }

        WaterData.saveHealthSyncedIDs(synced)
    }

    private static func save(_ entry: WaterEntry) async -> Bool {
        let sample = HKQuantitySample(
            type: waterType,
            quantity: HKQuantity(unit: ml, doubleValue: Double(entry.ml)),
            start: entry.at,
            end: entry.at,
            metadata: [
                HKMetadataKeySyncIdentifier: entry.id.uuidString,
                HKMetadataKeySyncVersion: 1,
            ]
        )
        return await withCheckedContinuation { cont in
            store.save(sample) { ok, _ in cont.resume(returning: ok) }
        }
    }

    private static func delete(syncID: String) async {
        let predicate = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeySyncIdentifier, allowedValues: [syncID]
        )
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            store.deleteObjects(of: waterType, predicate: predicate) { _, _, _ in cont.resume() }
        }
    }

    // MARK: - Okuma

    static func refreshFromHealth() async {
        guard isActive else { return }
        let start = Date().addingTimeInterval(-Double(readDays) * 86_400)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: nil)

        let samples: [HKQuantitySample]? = await withCheckedContinuation { cont in
            let query = HKSampleQuery(
                sampleType: waterType, predicate: predicate,
                limit: HKObjectQueryNoLimit, sortDescriptors: nil
            ) { _, results, error in
                cont.resume(returning: error == nil ? (results as? [HKQuantitySample] ?? []) : nil)
            }
            store.execute(query)
        }
        // Telefon kilitliyken okuma hata verir; eldeki kopyayı silme.
        guard let samples else { return }

        let ownPrefix = Bundle.main.bundleIdentifier ?? "com.atalay.creatinetracker"
        let ours = WaterData.healthSyncedIDs()
        var log: [String: [WaterEntry]] = [:]
        for s in samples {
            // Kendi yazdıklarımız (uygulama ya da ileride saat) sayılmasın.
            if s.sourceRevision.source.bundleIdentifier.hasPrefix(ownPrefix) { continue }
            if let id = s.metadata?[HKMetadataKeySyncIdentifier] as? String, ours.contains(id) { continue }
            let amount = Int(s.quantity.doubleValue(for: ml).rounded())
            guard amount > 0 else { continue }
            let entry = WaterEntry(id: s.uuid, ml: amount, at: s.startDate, fromHealth: true)
            log[DayKey.key(for: s.startDate), default: []].append(entry)
        }
        WaterData.saveHealth(log)
    }

    /// Eşitleme kapatılınca: diğer uygulamaların kopyasını unut. Sağlık'a
    /// yazdıklarımız orada kalıyor (kullanıcının verisi).
    static func forgetHealthCopy() {
        WaterData.saveHealth([:])
    }
}
