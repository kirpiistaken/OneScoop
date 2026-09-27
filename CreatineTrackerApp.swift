import SwiftUI
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
                // Dil değiştiyse bildirim butonu ve metinleri de yenilensin.
                NotificationManager.registerCategories()
                Task { await NotificationManager.reschedule() }
            }
        }
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
            WidgetCenter.shared.reloadAllTimelines()
            await MainActor.run { CreatineStore.shared.reload() }
        case UNNotificationDefaultActionIdentifier:
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
