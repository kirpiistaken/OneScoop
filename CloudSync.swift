import Foundation

/// Kayıtları ve ayarları kullanıcının kendi iCloud hesabında tutar
/// (NSUbiquitousKeyValueStore). Uygulama silinip yeniden yüklendiğinde ya da
/// aynı Apple hesabıyla başka bir cihaza kurulduğunda veriler geri gelir.
///
/// Sadece uygulama target'ında. Widget iCloud'a dokunmuyor; widget'tan yapılan
/// işaretlemeler uygulama bir sonraki açıldığında iCloud'a gidiyor.
///
/// Birleştirme kuralları:
/// - Günlük kayıtlar: her gün için en son olay kazanır. Olay ya bir kayıt
///   (takenAt) ya da bir geri alma (tombstone) olabilir.
/// - Ayarlar: en son değiştirilen kazanır (settings.updatedAt).
enum CloudSync {

    private static let logKey = "ct.log.v1"
    private static let tombKey = "ct.tombstones.v1"
    private static let settingsKey = "ct.settings.v1"
    private static let settingsAtKey = "ct.settings.updatedAt"
    private static let enabledKey = "ct.icloud.enabled"

    /// Güncellemeden önceki sürümlerde kaydedilmiş ayarların zaman damgası yok.
    /// Onlara eski bir tarih veriyoruz: iCloud boşsa yüklenirler, başka bir
    /// cihazdan gelen gerçek ayar varsa o kazanır.
    private static let legacySettingsDate = Date(timeIntervalSince1970: 1_577_836_800) // 2020-01-01

    /// 400 günden eski tombstone'lar atılıyor, depo şişmesin.
    private static let tombstoneLifetime: TimeInterval = 400 * 24 * 3600

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    private static var kv: NSUbiquitousKeyValueStore { .default }

    // MARK: - Açık / kapalı

    /// Kullanıcının tercihi. Varsayılan: açık. Bu tercih cihaza özel,
    /// iCloud'a gitmiyor.
    static var isEnabled: Bool {
        get { AppGroup.defaults.object(forKey: enabledKey) as? Bool ?? true }
        set { AppGroup.defaults.set(newValue, forKey: enabledKey) }
    }

    // MARK: - Başlatma

    private static var observer: NSObjectProtocol?

    /// Uygulama açılışında bir kez çağır.
    static func start(onRemoteChange: @escaping () -> Void) {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kv,
            queue: .main
        ) { _ in
            // İlk kurulumda iCloud verisi birkaç saniye sonra gelir; o an da burası tetiklenir.
            if sync() { onRemoteChange() }
        }
        kv.synchronize()
    }

    // MARK: - Senkron

    /// Yerel veriyi iCloud'dakiyle birleştirir, sonucu iki tarafa da yazar.
    /// Yerel veri değiştiyse `true` döner (ekranın yeniden yüklenmesi gerekir).
    @discardableResult
    static func sync() -> Bool {
        guard isEnabled else { return false }
        var localChanged = false

        // --- Günlük kayıtlar
        let remoteLog = decode([String: DoseEntry].self, kv.data(forKey: logKey)) ?? [:]
        let remoteTomb = decode([String: Date].self, kv.data(forKey: tombKey)) ?? [:]
        let localLog = Persistence.loadLog()
        let localTomb = Persistence.loadTombstones()

        let merged = merge(
            localLog: localLog, localTomb: localTomb,
            remoteLog: remoteLog, remoteTomb: remoteTomb
        )

        if merged.log != localLog {
            Persistence.saveLog(merged.log)
            localChanged = true
        }
        if merged.tomb != localTomb {
            Persistence.saveTombstones(merged.tomb)
        }
        if merged.log != remoteLog, let data = encode(merged.log) {
            kv.set(data, forKey: logKey)
        }
        if merged.tomb != remoteTomb, let data = encode(merged.tomb) {
            kv.set(data, forKey: tombKey)
        }

        // --- Ayarlar
        if Persistence.settingsUpdatedAt == nil, Persistence.hasStoredSettings {
            Persistence.saveSettings(Persistence.loadSettings(), updatedAt: legacySettingsDate)
        }

        let remoteAt = kv.double(forKey: settingsAtKey)          // yoksa 0
        let localAt = Persistence.settingsUpdatedAt?.timeIntervalSince1970

        if let data = kv.data(forKey: settingsKey),
           let remote = decode(DoseSettings.self, data),
           remoteAt > (localAt ?? 0) {
            Persistence.saveSettings(remote, updatedAt: Date(timeIntervalSince1970: remoteAt))
            localChanged = true
        } else if let localAt, localAt > remoteAt,
                  let data = encode(Persistence.loadSettings()) {
            kv.set(data, forKey: settingsKey)
            kv.set(localAt, forKey: settingsAtKey)
        }

        kv.synchronize()
        return localChanged
    }

    // MARK: - Birleştirme

    static func merge(
        localLog: [String: DoseEntry], localTomb: [String: Date],
        remoteLog: [String: DoseEntry], remoteTomb: [String: Date],
        now: Date = Date()
    ) -> (log: [String: DoseEntry], tomb: [String: Date]) {

        var tomb = localTomb
        for (day, date) in remoteTomb {
            tomb[day] = max(tomb[day] ?? .distantPast, date)
        }

        var log: [String: DoseEntry] = [:]
        for day in Set(localLog.keys).union(remoteLog.keys) {
            let newest: DoseEntry?
            switch (localLog[day], remoteLog[day]) {
            case let (a?, b?): newest = a.takenAt >= b.takenAt ? a : b
            case let (a?, nil): newest = a
            case let (nil, b?): newest = b
            default: newest = nil
            }
            guard let entry = newest else { continue }
            // Geri alma kayıttan sonra olduysa o gün silinmiş sayılır.
            if let removedAt = tomb[day], removedAt >= entry.takenAt { continue }
            log[day] = entry
        }

        // Kaydı olan günün tombstone'una gerek yok; çok eskileri de at.
        let cutoff = now.addingTimeInterval(-tombstoneLifetime)
        tomb = tomb.filter { day, date in log[day] == nil && date > cutoff }

        return (log, tomb)
    }

    // MARK: - Yardımcılar

    private static func decode<T: Decodable>(_ type: T.Type, _ data: Data?) -> T? {
        guard let data else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private static func encode<T: Encodable>(_ value: T) -> Data? {
        try? encoder.encode(value)
    }
}
