import StoreKit
import SwiftUI

// 2.0 — OneScoop+ tek seferlik satın alma (non-consumable, Aile Paylaşımı açık).
// Sadece uygulama target'ında. Ürün App Store Connect'te bu kimlikle açılacak.

@MainActor
final class PlusStore: ObservableObject {
    static let shared = PlusStore()
    static let productID = "com.atalay.creatinetracker.plus"

    @Published private(set) var product: Product?
    @Published private(set) var purchased = false
    @Published private(set) var isWorking = false

    var isUnlocked: Bool { purchased || PlusAccess.isUnlocked }

    private var updates: Task<Void, Never>?

    private init() {
        // Başka cihazdan / Aile Paylaşımı'ndan / iadeden gelen değişiklikler.
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result { await t.finish() }
                await self?.refresh()
            }
        }
    }

    func load() async {
        if product == nil {
            product = try? await Product.products(for: [Self.productID]).first
        }
        await refresh()
    }

    func refresh() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result,
               t.productID == Self.productID,
               t.revocationDate == nil {
                owned = true
            }
        }
        purchased = owned
        PlusAccess.setPurchased(owned)
        IntentRefresh.all()
    }

    func purchase() async {
        guard let product else { return }
        isWorking = true
        defer { isWorking = false }
        guard let result = try? await product.purchase() else { return }
        if case .success(let verification) = result, case .verified(let t) = verification {
            await t.finish()
            await refresh()
        }
    }

    func restore() async {
        isWorking = true
        defer { isWorking = false }
        try? await AppStore.sync()
        await refresh()
    }
}

// MARK: - Satın alma ekranı

struct PaywallView: View {
    @EnvironmentObject private var plus: PlusStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PlusHero()
                    .padding(.top, 28)

                VStack(spacing: 8) {
                    PlusWordmark(size: 34)
                    Text(L.plusHeadline)
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .foregroundStyle(CT.inkSoft)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    bullet("hand.tap.fill", L.plusBulletAnywhere)
                    bullet("applewatch", L.plusBulletWatch)
                    bullet("heart.fill", L.plusBulletHealth)
                    bullet("bell.badge.fill", L.plusBulletReminders)
                    bullet("waterbottle.fill", L.plusBulletCups)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CT.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                if plus.purchased {
                    Label(L.plusUnlocked, systemImage: "checkmark.seal.fill")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(CT.accent)
                } else {
                    buySection
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(CT.bg.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(CT.inkSoft)
                    .frame(width: 32, height: 32)
                    .background(CT.surface, in: Circle())
            }
            .padding(16)
            .accessibilityLabel(L.commonDone)
        }
        .task { await plus.load() }
    }

    private var buySection: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                if let price = plus.product?.displayPrice {
                    Text(verbatim: price)
                        .font(CT.display(34, .heavy))
                        .foregroundStyle(CT.ink)
                }
                Text(L.plusNoSubscription)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(CT.inkSoft)
            }

            Button {
                Task { await plus.purchase() }
            } label: {
                Group {
                    if plus.isWorking {
                        ProgressView().tint(.white)
                    } else {
                        Text(L.plusBuy)
                    }
                }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(CT.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PressableStyle())
            .disabled(plus.product == nil || plus.isWorking)
            .opacity(plus.product == nil ? 0.5 : 1)

            if plus.product == nil {
                Text(L.plusUnavailable)
                    .font(.footnote)
                    .foregroundStyle(CT.inkSoft)
                    .multilineTextAlignment(.center)
            }

            Button(L.plusRestore) { Task { await plus.restore() } }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(CT.accent)
                .disabled(plus.isWorking)

            Text(L.plusFamily)
                .font(.caption)
                .foregroundStyle(CT.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private func bullet(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(CT.accent)
                .frame(width: 24)
            Text(text)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(CT.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// "OneScoop" + altın renginde "+".
struct PlusWordmark: View {
    var size: CGFloat

    var body: some View {
        (Text(verbatim: "OneScoop").foregroundStyle(CT.ink)
         + Text(verbatim: "+").foregroundStyle(CT.gold))
            .font(CT.display(size, .heavy))
    }
}

/// Satın alma ekranının üstü: logodaki kepçe, altın renginde, üstünde taç.
struct PlusHero: View {
    @State private var shown = false
    private let size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle()
                .fill(CT.goldSoft)
                .frame(width: size * 1.35, height: size * 1.35)

            // Kepçe + taç birlikte, dairenin optik ortasına kaydırılmış:
            // kepçenin gövdesi solda ağır, taç üstte; ikisi beraber ortalanıyor.
            ZStack {
                ScoopShape()
                    .fill(LinearGradient(
                        colors: [CT.gold.opacity(0.75), CT.gold],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: size, height: size)
                    .scaleEffect(shown ? 1 : 0.85)

                // Tacı kepçenin ağzının üstüne oturt (ScoopShape koordinatlarından).
                Image(systemName: "crown.fill")
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundStyle(CT.gold)
                    .rotationEffect(.degrees(-10))
                    .offset(x: -165 / 870 * size, y: -195 / 870 * size - size * 0.2)
                    .offset(y: shown ? 0 : -14)
                    .opacity(shown ? 1 : 0)
            }
            .offset(x: 50 / 870 * size, y: size * 0.09)
        }
        .frame(height: size * 1.35)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.15)) { shown = true }
        }
    }
}
