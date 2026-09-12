import Foundation

/// Tek bir yerden değiştir: Xcode'da App Group capability'sine de aynısını yaz.
enum AppGroup {
    static let identifier = "group.com.atalay.creatinetracker"
    static let widgetKind = "CreatineWidget"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
