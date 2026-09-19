import SwiftUI
import UserNotifications
import WidgetKit

@main
struct CreatineTrackerApp: App {
    @StateObject private var store = CreatineStore.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // UNUserNotificationCenter.delegate ZAYIF bir referans tutar.
        // Delegate'i statik bir singleton'da saklamazsak nesne bellekten
        // silinir ve bildirime dokunulduğunda uygulama çöker.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationManager.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(CT.accent)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.reload()
                Task { await NotificationManager.reschedule() }
            }
        }
    }
}

/// Bildirimdeki "Log it" butonunu işler.
/// `shared` sayesinde uygulama ömrü boyunca hayatta kalır.
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
            WidgetCenter.shared.reloadAllTimelines()
            await MainActor.run { CreatineStore.shared.reload() }

        case UNNotificationDefaultActionIdentifier:
            // Bildirime dokunuldu, uygulama açılıyor. Ekranın güncel açılması
            // için veriyi tazeliyoruz; scenePhase da ayrıca tetikleniyor.
            await MainActor.run { CreatineStore.shared.reload() }

        default:
            break
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: CreatineStore

    var body: some View {
        Group {
            if store.settings.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.snappy, value: store.settings.hasCompletedOnboarding)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: CreatineStore

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "drop.fill") }

            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }

            SupplyView()
                .tabItem { Label("Supply", systemImage: "shippingbox.fill") }
                .badge(store.settings.supplyIsLow || store.settings.supplyIsEmpty ? "!" : nil)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
