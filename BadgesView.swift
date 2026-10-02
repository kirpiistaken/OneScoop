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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var index = 0
    @State private var appeared = false

    private var badge: Badge { badges[min(index, badges.count - 1)] }

    var body: some View {
        VStack(spacing: 14) {
            Text(badges.count > 1 ? L.celebrateMany(badges.count) : L.celebrateOne)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .tracking(2)
                .foregroundStyle(CT.accent)
                .padding(.top, 30)

            TabView(selection: $index) {
                ForEach(Array(badges.enumerated()), id: \.offset) { i, b in
                    VStack(spacing: 14) {
                        MedalView(badge: b, ribbon: progress.ribbon(for: b), width: 200)
                            .scaleEffect(appeared ? 1 : 0.4)
                            .rotationEffect(.degrees(appeared ? 0 : -12))
                        Text(verbatim: b.name)
                            .font(CT.display(32, .heavy))
                            .foregroundStyle(CT.ink)
                        Text(verbatim: b.detail)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(CT.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: badges.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            ShareCardButton(kind: .badge(badge, ribbon: progress.ribbon(for: badge)))
                .id(badge.id)
            Button(L.commonDone) { dismiss() }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(CT.inkSoft)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .background(CT.bg.ignoresSafeArea())
        .presentationDetents([.large])
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.1)) { appeared = true }
            maybeAskForReview()
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
