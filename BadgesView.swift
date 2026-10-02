import SwiftUI
import StoreKit

// 2.1 — Rozetler ekranı ve yeni rozet kutlaması (ücretsiz).

struct BadgesView: View {
    @EnvironmentObject private var store: CreatineStore
    @Environment(\.dismiss) private var dismiss
    @State private var filter: Filter = .all
    @State private var selected: Badge?

    enum Filter: Hashable { case all, creatine, water }

    private var progress: BadgeProgress { store.badgeProgress }

    private var visible: [Badge] {
        Badge.all.filter { b in
            switch filter {
            case .all: return store.water.enabled || b.group != .water
            case .creatine: return b.group == .creatine || (b.group == .special)
            case .water: return b.group == .water
            }
        }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    nextCard
                    if store.water.enabled {
                        Picker(selection: $filter) {
                            Text(L.badgesAll).tag(Filter.all)
                            Text(L.historyCreatine).tag(Filter.creatine)
                            Text(L.waterTitle).tag(Filter.water)
                        } label: { EmptyView() }
                        .pickerStyle(.segmented)
                    }
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(visible) { b in
                            Button { selected = b } label: { cell(b) }
                                .buttonStyle(PressableStyle())
                        }
                    }
                    Text(L.badgesRuleNote)
                        .font(.footnote)
                        .foregroundStyle(CT.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .background(CT.bg.ignoresSafeArea())
            .navigationTitle(L.badgesTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.commonDone) { dismiss() }
                }
            }
            .sheet(item: $selected) { b in
                BadgeDetailSheet(badge: b, progress: progress)
            }
        }
    }

    private var nextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let next = progress.next(in: .creatine), let days = next.badge.days {
                HStack(alignment: .firstTextBaseline) {
                    Text(L.badgesNext(next.badge.name))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(CT.ink)
                    Spacer()
                    Text(L.badgesDaysLeft(next.remaining))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(CT.inkSoft)
                }
                ProgressView(value: Double(days - next.remaining), total: Double(days))
                    .tint(CT.accent)
            } else {
                Text(L.badgesAllStreaks)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(CT.ink)
            }
            HStack {
                Text(L.badgesEarned(progress.earnedCount, Badge.all.count))
                    .font(.footnote)
                    .foregroundStyle(CT.inkSoft)
                Spacer()
                if progress.creatineStreak >= 2 {
                    ShareLinkCompact(kind: .streak(days: progress.creatineStreak, last28: last28()))
                }
            }
        }
        .padding(16)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func cell(_ b: Badge) -> some View {
        let earned = progress.isEarned(b)
        return VStack(spacing: 6) {
            MedalView(badge: b, ribbon: progress.ribbon(for: b), locked: !earned, width: 96)
                .opacity(earned ? 1 : 0.7)
            Text(verbatim: b.name)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(earned ? CT.ink : CT.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    /// Son 28 gün: zamanında kreatin girilen günler.
    private func last28() -> [Bool] {
        let genuine = Badges.genuineDays(store.log)
        let today = DayKey.startOfDay(Date())
        return (0..<28).reversed().map { back in
            let d = DayKey.calendar.date(byAdding: .day, value: -back, to: today) ?? today
            return genuine.contains(DayKey.key(for: d))
        }
    }
}

/// Seri kartı için küçük paylaş düğmesi.
private struct ShareLinkCompact: View {
    var kind: ShareCardKind
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview(Text(verbatim: "OneScoop"), image: Image(uiImage: image))
                ) {
                    Label(L.shareStreakButton, systemImage: "square.and.arrow.up")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(CT.accent)
                }
            }
        }
        .task { image = ShareCardView.render(kind) }
    }
}

// MARK: - Rozet ayrıntısı

struct BadgeDetailSheet: View {
    var badge: Badge
    var progress: BadgeProgress
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let earned = progress.isEarned(badge)
        VStack(spacing: 16) {
            MedalView(badge: badge, ribbon: progress.ribbon(for: badge), locked: !earned, width: 170)
                .padding(.top, 28)
            Text(verbatim: badge.name)
                .font(CT.display(28, .heavy))
                .foregroundStyle(CT.ink)
            Text(verbatim: badge.detail)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(CT.inkSoft)
                .multilineTextAlignment(.center)
            if let date = progress.earned[badge.id] {
                Text(L.badgesEarnedOn(date.formatted(date: .long, time: .omitted)))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(CT.accent)
            }
            Spacer(minLength: 8)
            if earned {
                ShareCardButton(kind: .badge(badge, ribbon: progress.ribbon(for: badge)))
            }
            Button(L.commonDone) { dismiss() }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(CT.inkSoft)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(CT.bg.ignoresSafeArea())
        .presentationDetents([.large])
    }
}

// MARK: - Yeni rozet kutlaması

struct BadgeCelebrationView: View {
    var badges: [Badge]
    var progress: BadgeProgress
    var preview = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var index = 0
    @State private var appeared = false

    private var badge: Badge { badges[min(index, badges.count - 1)] }
    private var palette: MedalPalette { MedalPalette.of(badge.tier) }

    var body: some View {
        ZStack {
            // Sahne: koyu zemin, seviye renginde ışık, dönen ışınlar, pırıltılar
            Color(hex: 0x0A0F1F).ignoresSafeArea()
            CelebrationStage(color: palette.c1, glow: palette.glow, appeared: appeared)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: badge.id)

            VStack(spacing: 0) {
                Text(badges.count > 1 ? L.celebrateMany(badges.count) : L.celebrateOne)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(palette.c1)
                    .padding(.top, 36)
                    .opacity(appeared ? 1 : 0)

                TabView(selection: $index) {
                    ForEach(Array(badges.enumerated()), id: \.offset) { i, b in
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            MedalView(badge: b, ribbon: progress.earnedRibbon(for: b), width: 250)
                                .scaleEffect(appeared ? 1 : 0.3)
                                .rotationEffect(.degrees(appeared ? 0 : -18))
                                .opacity(appeared ? 1 : 0)
                            Text(verbatim: b.name)
                                .font(CT.display(38, .black))
                                .foregroundStyle(.white)
                                .padding(.top, 26)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Text(verbatim: b.detail)
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color(hex: 0xB9C3D8))
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 24)
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: badges.count > 1 ? .always : .never))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 12) {
                    ShareCardButton(kind: .badge(badge, ribbon: progress.earnedRibbon(for: badge)))
                        .id(badge.id)
                    Button(L.commonDone) { dismiss() }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color(hex: 0x8A92A3))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .environment(\.colorScheme, .dark)
        .presentationDetents([.large])
        .presentationBackground(Color(hex: 0x0A0F1F))
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.7, dampingFraction: 0.55).delay(0.15)) { appeared = true }
            if !preview { maybeAskForReview() }
        }
    }

    /// Puan isteme: kullanıcının en mutlu anı, yani seri rozetleri. iOS yılda
    /// en fazla 3 kez gösteriyor; her rozet için bir kez soruyoruz.
    private func maybeAskForReview() {
        let ask = ["c7", "c30", "c100", "w30"]
        var asked = Set(AppGroup.defaults.stringArray(forKey: "ct.review.askedFor") ?? [])
        guard let id = badges.map(\.id).first(where: { ask.contains($0) && !asked.contains($0) }) else { return }
        asked.insert(id)
        AppGroup.defaults.set(Array(asked), forKey: "ct.review.askedFor")
        Task {
            try? await Task.sleep(for: .seconds(2))
            requestReview()
        }
    }
}

// MARK: - Kutlama sahnesi

/// Rozetin arkasındaki ışık: yumuşak bloom, yavaş dönen ışınlar, yanıp sönen
/// pırıltılar ve rozet gelince bir kez açılan ışık halkası.
private struct CelebrationStage: View {
    var color: Color
    var glow: Color
    var appeared: Bool

    @State private var spin = false
    @State private var pulse = false
    @State private var burst = false

    // Pırıltıların yerleri (ekranın oranı), boyutları ve gecikmeleri sabit.
    private let sparkles: [(CGFloat, CGFloat, CGFloat, Double)] = [
        (0.18, 0.22, 14, 0.0), (0.82, 0.18, 10, 0.6), (0.12, 0.48, 9, 1.1),
        (0.88, 0.44, 16, 0.3), (0.26, 0.66, 8, 0.9), (0.76, 0.68, 12, 1.4),
        (0.5, 0.14, 9, 1.8), (0.62, 0.30, 7, 0.4), (0.36, 0.30, 7, 1.6),
        (0.93, 0.58, 8, 2.1), (0.07, 0.34, 11, 2.4), (0.55, 0.74, 7, 0.7),
    ]

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.42)
            ZStack {
                // Geniş ve yumuşak bloom
                RadialGradient(colors: [glow.opacity(0.9), glow.opacity(0.25), .clear],
                               center: .center, startRadius: 0, endRadius: geo.size.width * 0.75)
                    .frame(width: geo.size.width * 1.6, height: geo.size.width * 1.6)
                    .scaleEffect(pulse ? 1.06 : 0.94)
                    .position(center)

                // Dönen ışınlar
                Rays(count: 18)
                    .fill(AngularGradient(colors: [color.opacity(0.16), color.opacity(0.02), color.opacity(0.16)],
                                          center: .center))
                    .frame(width: geo.size.width * 1.9, height: geo.size.width * 1.9)
                    .mask(RadialGradient(colors: [.white, .white.opacity(0.4), .clear],
                                         center: .center, startRadius: 40, endRadius: geo.size.width * 0.9))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .position(center)
                    .opacity(appeared ? 1 : 0)

                // Rozet gelince açılan ışık halkası
                Circle()
                    .stroke(color.opacity(burst ? 0 : 0.7), lineWidth: burst ? 1 : 6)
                    .frame(width: 120, height: 120)
                    .scaleEffect(burst ? 4.5 : 0.6)
                    .position(center)

                // Pırıltılar
                ForEach(sparkles.indices, id: \.self) { i in
                    let sp = sparkles[i]
                    Sparkle(color: color, size: sp.2, delay: sp.3)
                        .position(x: geo.size.width * sp.0, y: geo.size.height * sp.1)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.easeOut(duration: 1.1).delay(0.25)) { burst = true }
        }
    }
}

private struct Rays: Shape {
    var count: Int
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = max(rect.width, rect.height) / 2
        let half = CGFloat.pi / CGFloat(count) * 0.45
        for i in 0..<count {
            let a = CGFloat(i) / CGFloat(count) * 2 * .pi
            p.move(to: c)
            p.addLine(to: CGPoint(x: c.x + r * cos(a - half), y: c.y + r * sin(a - half)))
            p.addLine(to: CGPoint(x: c.x + r * cos(a + half), y: c.y + r * sin(a + half)))
            p.closeSubpath()
        }
        return p
    }
}

private struct Sparkle: View {
    var color: Color
    var size: CGFloat
    var delay: Double
    @State private var on = false

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(.white)
            .shadow(color: color, radius: 6)
            .scaleEffect(on ? 1 : 0.2)
            .opacity(on ? 0.95 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true).delay(delay)) { on = true }
            }
    }
}
