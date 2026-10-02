import Foundation
import WidgetKit

@MainActor
final class CreatineStore: ObservableObject {
    static let shared = CreatineStore()

    @Published private(set) var settings: DoseSettings
    @Published private(set) var log: [String: DoseEntry]
    @Published private(set) var iCloudEnabled: Bool

    // 2.0 — Su
    @Published private(set) var water: WaterSettings
    @Published private(set) var waterToday: [WaterEntry]

    /// Yeni kurulumda iCloud'dan eski veriler beklenirken `true`.
    /// Bu sürede kurulum ekranı yerine "iCloud'da aranıyor" ekranı gösteriliyor;
    /// böylece geri dönen kullanıcı kurulumu görmeden kaldığı yerden devam ediyor.
    @Published private(set) var isRestoring: Bool

    // 2.1 — Rozetler
    struct BadgeBatch: Identifiable {
        let id = UUID()
        let badges: [Badge]
    }
    @Published private(set) var badgeProgress: BadgeProgress
    /// Yeni kazanılan rozetler; doluyken kutlama ekranı açılır.
    @Published var celebration: BadgeBatch?

    /// iCloud verisi yeni kurulumda genelde birkaç saniyede gelir. Bu süre
    /// dolarsa (gerçekten yeni kullanıcıysa) kurulum ekranına geçilir.
    private static let restoreTimeout: Duration = .seconds(6)

    private init() {
        settings = Persistence.loadSettings()
        log = Persistence.loadLog()
        iCloudEnabled = CloudSync.isEnabled
        water = WaterData.loadSettings()
        waterToday = WaterData.entries()
        badgeProgress = BadgeProgress(
            earned: Badges.loadEarned(), creatineStreak: 0, waterStreak: 0,
            loadingDays: 7, monthDays: 30
        )

        // Sadece: hiç ayar kaydı yok (yeni kurulum), iCloud açık ve iPhone'da
        // iCloud hesabı var. Aksi halde beklemenin anlamı yok.
        isRestoring = !Persistence.hasStoredSettings
            && CloudSync.isEnabled
            && FileManager.default.ubiquityIdentityToken != nil

        if isRestoring {
            Task { [weak self] in
                try? await Task.sleep(for: Self.restoreTimeout)
                self?.isRestoring = false
            }
        }
    }

    func reload() {
        settings = Persistence.loadSettings()
        log = Persistence.loadLog()
        water = WaterData.loadSettings()
        waterToday = WaterData.entries()
    }

    /// Uygulama öne geldiğinde: widget'tan/bildirimden/saatten gelenleri al,
    /// iCloud ile birleştir, her yeri güncelle.
    func becameActive() {
        if CloudSync.sync() {
            applyRemoteChange()
        } else {
            reload()
            checkBadges()
            PhoneWatchBridge.shared.pushStatus()
            // Gün değişmiş olabilir: widget'lar ve Denetim Merkezi düğmesi
            // dünkü durumda kalmasın.
            IntentRefresh.all()
        }
    }

    /// iCloud'dan başka bir cihazın değişikliği geldiğinde.
    func applyRemoteChange() {
        let wasOnboarded = settings.hasCompletedOnboarding
        reload()
        if settings.hasCompletedOnboarding { isRestoring = false }
        checkBadges()

        IntentRefresh.all()
        PhoneWatchBridge.shared.pushStatus()

        // iCloud'dan geri yüklenen kullanıcı kurulumu görmediği için bildirim
        // iznini de hiç vermedi. Hatırlatma açıksa izni burada iste.
        let needsPermission = !wasOnboarded
            && settings.hasCompletedOnboarding
            && settings.reminderEnabled
        Task {
            if needsPermission,
               await NotificationManager.authorizationStatus() == .notDetermined {
                _ = await NotificationManager.requestAuthorization()
            }
            await NotificationManager.reschedule()
            // Kreatin saati değişince su bildirimleri ona göre kaysın.
            await WaterReminders.reschedule()
        }
    }

    // MARK: - Türetilmiş

    var todayDose: Double { settings.dose(on: Date()) }
    var isTodayTaken: Bool { log[DayKey.today] != nil }
    var todayEntry: DoseEntry? { log[DayKey.today] }
    var streak: Int { Stats.streak(log: log) }

    func entry(for date: Date) -> DoseEntry? { log[DayKey.key(for: date)] }

    // MARK: - Rozetler (2.1)

    /// Kayıtlara bakıp rozetleri günceller; yeni kazanılan varsa kutlama açar.
    func checkBadges() {
        guard settings.hasCompletedOnboarding else { return }
        let result = Badges.evaluate()
        badgeProgress = result.progress
        if !result.new.isEmpty {
            CloudSync.sync()      // kazanılan rozet diğer cihazlara da gitsin
            celebration = BadgeBatch(badges: result.new)
        }
    }

    // MARK: - Eylemler

    func markTaken(on date: Date = Date()) {
        log = Persistence.markTaken(on: date)
        settings = Persistence.loadSettings()   // stok düşmüş olabilir
        syncSideEffects()
    }

    // MARK: Porsiyonlar (2.1)

    /// Bugün kaç porsiyon gerekiyor (yükleme günü ve bölünmüşse >1).
    var portionsNeeded: Int { settings.portions(on: Date()) }
    var portionsToday: Int { _ = log; return Persistence.portions() }

    /// Bir porsiyon işaretle; sonuncusuysa gün tamamlanır.
    func takePortion() {
        let needed = portionsNeeded
        guard needed > 1 else { markTaken(); return }
        let done = min(needed, Persistence.portions() + 1)
        Persistence.setPortions(done)
        if done >= needed {
            markTaken()
        } else {
            objectWillChange.send()
        }
    }

    func undoPortion() {
        Persistence.setPortions(Persistence.portions() - 1)
        objectWillChange.send()
    }

    func undo(on date: Date = Date()) {
        // Bölünmüş günde geri alınca son porsiyon geri gelir.
        if DayKey.key(for: date) == DayKey.today, portionsNeeded > 1 {
            Persistence.setPortions(portionsNeeded - 1)
        }
        log = Persistence.undo(on: date)
        settings = Persistence.loadSettings()   // stok geri eklenmiş olabilir
        syncSideEffects()
    }

    func update(_ transform: (inout DoseSettings) -> Void) {
        var copy = settings
        transform(&copy)
        settings = copy
        Persistence.saveSettings(copy)
        syncSideEffects()
    }

    func restock(to grams: Double? = nil) {
        Persistence.restock(to: grams)
        settings = Persistence.loadSettings()
        syncSideEffects()
    }

    func setICloudEnabled(_ enabled: Bool) {
        CloudSync.isEnabled = enabled
        iCloudEnabled = enabled
        if enabled, CloudSync.sync() {
            applyRemoteChange()
        }
    }

    func completeOnboarding() {
        update {
            $0.hasCompletedOnboarding = true
            $0.startDate = DayKey.startOfDay(Date())
        }
        Task {
            _ = await NotificationManager.requestAuthorization()
            await NotificationManager.reschedule()
        }
    }

    func resetEverything() {
        Persistence.resetAll()
        WaterData.resetAll()
        CloudSync.sync()          // silmeyi iCloud'a ve diğer cihazlara da taşı
        reload()
        Task { await NotificationManager.cancelAll() }
        IntentRefresh.all()
        PhoneWatchBridge.shared.pushStatus()
    }

    // MARK: - Su

    var waterTotalToday: Int { waterToday.reduce(0) { $0 + $1.ml } }

    @discardableResult
    func addWater(_ ml: Int) -> WaterEntry {
        let entry = WaterData.add(ml: ml)
        CloudSync.sync()
        waterToday = WaterData.entries()
        checkBadges()
        IntentRefresh.all()
        PhoneWatchBridge.shared.pushStatus()
        Task {
            await WaterReminders.reschedule()
            await HealthSync.pushLocalChanges()
        }
        return entry
    }

    /// En son girilen suyu siler. Art arda basılınca sırayla geri gider.
    /// Sağlık'tan gelen kayıtlar atlanır (onlar başka uygulamanın).
    func undoLastWater() {
        guard let last = waterToday.filter({ !$0.isFromHealth }).max(by: { $0.at < $1.at }) else { return }
        removeWater(last.id)
    }

    var canUndoWater: Bool { waterToday.contains { !$0.isFromHealth } }

    /// Apple Sağlık eşitlemesini aç/kapat. Açarken izin istenir.
    func setHealthEnabled(_ on: Bool) async {
        if on { _ = await HealthSync.requestAccess() }
        updateWater { $0.healthEnabled = on }
        if on {
            await HealthSync.syncAll()
            HealthSync.startObserving()
        } else {
            HealthSync.forgetHealthCopy()
            HealthSync.stopObserving()
        }
        waterToday = WaterData.entries()
        IntentRefresh.all()
        await WaterReminders.reschedule()
    }

    /// Antrenman günü hedefi aç/kapat (Sağlık'tan antrenman okuma izni ister).
    func setWorkoutBoost(_ on: Bool) async {
        if on { _ = await HealthSync.requestAccess() }
        updateWater { $0.workoutBoostEnabled = on }
        if on { await HealthSync.refreshWorkoutDays() }
        objectWillChange.send()
        IntentRefresh.all()
        PhoneWatchBridge.shared.pushStatus()
        await WaterReminders.reschedule()
    }

    /// Uygulama öne gelince: widget'tan girilenleri Sağlık'a yaz, Sağlık'taki
    /// diğer uygulamaların sularını al.
    func refreshHealth() async {
        guard HealthSync.isActive else { return }
        await HealthSync.syncAll()
        waterToday = WaterData.entries()
        checkBadges()
        IntentRefresh.all()
        await WaterReminders.reschedule()
    }

    func removeWater(_ id: UUID) {
        WaterData.remove(id)
        CloudSync.sync()
        waterToday = WaterData.entries()
        IntentRefresh.all()
        PhoneWatchBridge.shared.pushStatus()
        Task {
            await WaterReminders.reschedule()
            await HealthSync.pushLocalChanges()
        }
    }

    func updateWater(_ transform: (inout WaterSettings) -> Void) {
        var copy = water
        transform(&copy)
        water = copy
        WaterData.saveSettings(copy)
        CloudSync.sync()
        IntentRefresh.all()
        PhoneWatchBridge.shared.pushStatus()
        NotificationManager.registerCategories()   // "+250 ml" düğmesi varsayılan kabı izlesin
        Task { await WaterReminders.reschedule() }
    }

    private func syncSideEffects() {
        if CloudSync.sync() { reload() }
        checkBadges()
        IntentRefresh.all()
        PhoneWatchBridge.shared.pushStatus()
        Task { await NotificationManager.reschedule() }
    }
}
