import SwiftUI
import UserNotifications

@main
struct CreatineTrackerApp: App {
    @StateObject private var store = CreatineStore.shared
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var delegate = NotificationDelegate()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(CT.accent)
                .onAppear {
                    UNUserNotificationCenter.current().delegate = delegate
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // Widget'tan yapılmış olabilecek değişiklikleri al.
                store.reload()
                Task { await NotificationManager.reschedule() }
            }
        }
    }
}

final class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
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
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "drop.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
