import SwiftUI
import UIKit

// 2.0 — Alternatif uygulama ikonları (OneScoop+). Sadece uygulama target'ında.
// İkonlar Assets.xcassets'te (AppIconGold/Night/Light); önizlemeleri ayrı
// imageset olarak duruyor çünkü appiconset UIImage ile açılamıyor.

enum AppIconOption: String, CaseIterable, Identifiable {
    case classic, gold, night, light

    var id: String { rawValue }

    /// setAlternateIconName'e giden ad (klasik = nil).
    var iconName: String? {
        switch self {
        case .classic: nil
        case .gold: "AppIconGold"
        case .night: "AppIconNight"
        case .light: "AppIconLight"
        }
    }

    var preview: String {
        switch self {
        case .classic: "AppIconDefaultPreview"
        case .gold: "AppIconGoldPreview"
        case .night: "AppIconNightPreview"
        case .light: "AppIconLightPreview"
        }
    }

    var title: String {
        switch self {
        case .classic: L.iconClassic
        case .gold: L.iconGold
        case .night: L.iconNight
        case .light: L.iconLight
        }
    }

    static var current: AppIconOption {
        let name = UIApplication.shared.alternateIconName
        return allCases.first { $0.iconName == name } ?? .classic
    }

    @MainActor
    static func apply(_ option: AppIconOption) async {
        guard UIApplication.shared.supportsAlternateIcons,
              UIApplication.shared.alternateIconName != option.iconName else { return }
        try? await UIApplication.shared.setAlternateIconName(option.iconName)
    }
}

struct AppIconPicker: View {
    @EnvironmentObject private var plus: PlusStore
    @Environment(\.dismiss) private var dismiss
    @State private var selected = AppIconOption.current
    @State private var showPaywall = false

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(AppIconOption.allCases) { option in
                        Button { choose(option) } label: {
                            VStack(spacing: 8) {
                                Image(option.preview)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 88, height: 88)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(selected == option ? CT.accent : CT.hairline,
                                                    lineWidth: selected == option ? 3 : 1)
                                    )
                                HStack(spacing: 4) {
                                    Text(option.title)
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(CT.ink)
                                    if option != .classic && !plus.isUnlocked {
                                        Image(systemName: "crown.fill")
                                            .font(.caption2)
                                            .foregroundStyle(CT.gold)
                                    }
                                }
                            }
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(24)
            }
            .background(CT.bg.ignoresSafeArea())
            .navigationTitle(L.settingsAppIcon)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.commonDone) { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func choose(_ option: AppIconOption) {
        guard option == .classic || plus.isUnlocked else {
            showPaywall = true
            return
        }
        selected = option
        Task { await AppIconOption.apply(option) }
    }
}
