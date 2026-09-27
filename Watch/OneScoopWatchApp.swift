import SwiftUI

@main
struct OneScoopWatchApp: App {
    @StateObject private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(model)
        }
    }
}
