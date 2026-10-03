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
    /// TestFlight / sandbox'ta çalışıyor mu (test satın alması sadece orada).
    @Published private(set) var isTestBuild = BuildFlags.testPurchaseEnabled && PlusAccess.isTestBuild
    @Published private(set) var simulated = PlusAccess.isSimulated

    var isUnlocked: Bool { purchased || (isTestBuild && simulated) }

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
        await detectTestBuild()
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
        PhoneWatchBridge.shared.pushStatus()
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

    // MARK: - Test satın alması (sadece TestFlight)

    private func detectTestBuild() async {
        var test = false
        if case .verified(let app)? = try? await AppTransaction.shared {
            test = app.environment != .production
        } else {
            // AppTransaction alınamazsa eski yöntem: TestFlight'ta fiş adı böyle.
            test = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        }
        // Test satın alması sadece dev build'lerinde (BuildFlags); main/review'da hiç yok.
        isTestBuild = BuildFlags.testPurchaseEnabled && test
        PlusAccess.setTestBuild(isTestBuild)
        simulated = PlusAccess.isSimulated
    }

    /// Gerçek ödeme yok; App Store'un satın alma anını taklit ediyor.
    func simulatePurchase() async {
        guard isTestBuild else { return }
        isWorking = true
        try? await Task.sleep(for: .seconds(1.2))
        PlusAccess.setSimulated(true)
        simulated = true
        isWorking = false
        await applyChange()
    }

    func cancelSimulatedPurchase() async {
        PlusAccess.setSimulated(false)
        simulated = false
        await AppIconOption.apply(.classic)
        await applyChange()
    }

    /// Plus açılıp kapanınca: widget'lar, hatırlatmalar, Sağlık kopyası.
    private func applyChange() async {
        IntentRefresh.all()
        PhoneWatchBridge.shared.pushStatus()
        CreatineStore.shared.reload()
        await WaterReminders.reschedule()
        await CreatineStore.shared.refreshHealth()
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
    @State private var confirmTestPurchase = false

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

                // Sadece OneScoop+ ile gelenler. Kreatin tarafı ve su takibinin
                // kendisi (üç kap, basit hatırlatma, takvim) herkese açık.
                // Asıl satış noktası: uygulamayı açmadan su eklemek.
                PlusWidgetFeature()

                VStack(alignment: .leading, spacing: 16) {
                    bullet("chart.xyaxis.line", L.plusBulletInsights)
                    bullet("bell.badge.fill", L.plusBulletReminders)
                    bullet("figure.strengthtraining.traditional", L.plusBulletWorkout)
                    bullet("heart.fill", L.plusBulletHealth)
                    bullet("applewatch", L.plusBulletWatch)
                    bullet("app.badge.fill", L.plusBulletIcons)
                    bullet("square.and.arrow.up", L.plusBulletExport)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CT.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                if plus.isUnlocked {
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
                if plus.isTestBuild {
                    confirmTestPurchase = true
                } else {
                    Task { await plus.purchase() }
                }
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
            .disabled((plus.product == nil && !plus.isTestBuild) || plus.isWorking)
            .opacity(plus.product == nil && !plus.isTestBuild ? 0.5 : 1)
            // TestFlight: gerçek ödeme yok, Ayarlar'dan geri alınabiliyor.
            .confirmationDialog(L.plusTestTitle, isPresented: $confirmTestPurchase, titleVisibility: .visible) {
                Button(L.plusTestBuy) { Task { await plus.simulatePurchase() } }
                Button(L.commonCancel, role: .cancel) {}
            } message: {
                Text(L.plusTestMessage)
            }

            if plus.isTestBuild {
                Label(L.plusTestNote, systemImage: "hammer.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CT.inkSoft)
            } else if plus.product == nil {
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

/// Satın alma ekranındaki öne çıkan özellik: küçük bir su widget'ı çizimi
/// ve "Uygulamayı açmadan su ekle".
struct PlusWidgetFeature: View {
    var body: some View {
        HStack(spacing: 16) {
            // Minyatür widget: bardak, toplam, üç kap
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .bottom, spacing: 8) {
                    WaterGlass(fraction: 0.55, wavePhase: 1)
                        .frame(width: 22, height: 32)
                    Text(verbatim: "1,25 L")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(CT.ink)
                }
                HStack(spacing: 5) {
                    ForEach(WaterCup.Kind.allCases, id: \.self) { kind in
                        CupIcon(kind: kind)
                            .fill(CT.accent)
                            .frame(width: 11, height: 11)
                            .frame(width: 22, height: 22)
                            .background(CT.accent.opacity(0.14), in: Circle())
                    }
                }
            }
            .padding(10)
            .background(CT.bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(CT.hairline, lineWidth: 1))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(L.plusWidgetTitle)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(CT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L.plusWidgetSubtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
