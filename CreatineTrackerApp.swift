import SwiftUI
import UserNotifications
import WidgetKit

@main
struct CreatineTrackerApp: App {
    @StateObject private var store = CreatineStore.shared
    @Environment(\.scenePhase) private var scenePhase
    private let delegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = delegate
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
                // Widget'tan veya bildirimden yapılmış değişiklikleri al.
                store.reload()
                Task { await NotificationManager.reschedule() }
            }
        }
    }
}

/// Bildirimdeki "Log it" butonunu işler. Uygulama açılmadan çalışır.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

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
        guard response.actionIdentifier == NotificationManager.logActionID else { return }

        Persistence.markTaken()
        await NotificationManager.reschedule()
        WidgetCenter.shared.reloadAllTimelines()
        await MainActor.run { CreatineStore.shared.reload() }
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

