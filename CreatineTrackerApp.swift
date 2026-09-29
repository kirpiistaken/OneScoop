import SwiftUI
import StoreKit
import BackgroundTasks
import UserNotifications
import WidgetKit

@main
struct CreatineTrackerApp: App {
    @StateObject private var store = CreatineStore.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // delegate ZAYIF referans — singleton'da tutmazsak bildirime dokununca çöker.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationManager.registerCategories()

        // Saat komutları uygulama kapalıyken de gelebilir; en başta dinlemeye başla.
        PhoneWatchBridge.shared.activate()

        // iCloud'dan başka bir cihazın değişikliği gelince ekranı yenile.
        CloudSync.start {
            Task { @MainActor in CreatineStore.shared.applyRemoteChange() }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(CT.accent)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.becameActive()
                MidnightRefresh.schedule()
                // Dil değiştiyse bildirim butonu ve metinleri de yenilensin.
                NotificationManager.registerCategories()
                Task { await NotificationManager.reschedule() }
            }
        }
        .backgroundTask(.appRefresh(MidnightRefresh.identifier)) {
            await MidnightRefresh.run()
        }
    }
}

/// Gece yarısından sonra widget'ları ve Denetim Merkezi düğmesini yeniler.
/// Uygulama hiç açılmasa ve ekranda widget olmasa bile düğme dünkü
/// "alındı" durumunda kalmasın diye. Zamanı iOS belirler; gece yarısından
/// biraz sonra, telefon uygun olduğunda çalışır.
enum MidnightRefresh {
    static let identifier = "com.atalay.creatinetracker.midnight"

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = DayKey.nextMidnight.addingTimeInterval(60)
        try? BGTaskScheduler.shared.submit(request)
    }

    static func run() async {
        schedule()
        IntentRefresh.all()
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationDelegate()
    private override init() { super.init() }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        switch response.actionIdentifier {
        case NotificationManager.logActionID:
            Persistence.markTaken()
            await NotificationManager.reschedule()
            IntentRefresh.all()
            await MainActor.run {
                CloudSync.sync()
                CreatineStore.shared.reload()
                PhoneWatchBridge.shared.pushStatus()
            }
        case UNNotificationDefaultActionIdentifier:
            await MainActor.run { CreatineStore.shared.reload() }
        default:
            break
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: CreatineStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @State private var countedThisLaunch = false

    var body: some View {
        Group {
            if store.settings.hasCompletedOnboarding {
                MainTabView()
            } else if store.isRestoring {
                RestoringView()
            } else {
                OnboardingView()
            }
        }
        .animation(.snappy, value: store.settings.hasCompletedOnboarding)
        .animation(.snappy, value: store.isRestoring)
        .onChange(of: scenePhase, initial: true) { old, new in
            // Bir "açılış" = soğuk başlatma ya da arka plandan öne gelme.
            // İzin penceresi gibi sistem diyaloglarından dönüş (.inactive → .active)
            // açılış sayılmaz.
            guard new == .active else { return }
            guard old == .background || !countedThisLaunch else { return }
            countedThisLaunch = true
            maybeAskForReview(opens: OpenCounter.registerOpen())
        }
    }

    /// Ömürde bir kez, 3. açılışta App Store puanlama penceresini ister.
    /// Kurulum henüz bitmediyse bir sonraki açılışa kalır.
    private func maybeAskForReview(opens: Int) {
        guard opens >= 3,
              store.settings.hasCompletedOnboarding,
              !store.settings.hasAskedForReview else { return }

        // Bayrağı istekten ÖNCE yazıyoruz: iOS pencereyi göstermeyebilir,
        // yine de bir daha denemiyoruz.
        store.update { $0.hasAskedForReview = true }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            requestReview()
        }
    }
}

/// Yeni kurulumda iCloud'dan eski veriler beklenirken gösterilen kısa ekran.
struct RestoringView: View {
    var body: some View {
        ZStack {
            CT.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(CT.accent)
                Text(L.restoreChecking)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(CT.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }
}

/// Uygulamanın kaç kez açıldığını sayar. Sadece uygulamaya ait,
/// widget ile paylaşılmadığı için standart UserDefaults yeterli.
enum OpenCounter {
    private static let key = "ct.openCount.v1"

    @discardableResult
    static func registerOpen() -> Int {
        let count = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(count, forKey: key)
        return count
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: CreatineStore

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label(L.tabToday, systemImage: "drop.fill") }

            HistoryView()
                .tabItem { Label(L.tabHistory, systemImage: "calendar") }

            SupplyView()
                .tabItem { Label(L.tabSupply, systemImage: "shippingbox.fill") }
                .badge(store.settings.supplyIsLow || store.settings.supplyIsEmpty ? "!" : nil)

            SettingsView()
                .tabItem { Label(L.tabSettings, systemImage: "gearshape") }
        }
    }
}
