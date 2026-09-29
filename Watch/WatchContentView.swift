import SwiftUI
import WatchKit

/// Saatte tek ekran: soru, "Yes" butonu ve seri. Takvim ve ayarlar yok.
struct WatchContentView: View {
    @EnvironmentObject private var model: WatchModel
    @Environment(\.scenePhase) private var scenePhase

    private let accent = Color(red: 0.36, green: 0.53, blue: 1.0)      // #5C86FF
    private let soft = Color(red: 0.58, green: 0.61, blue: 0.65)       // #939CA6

    var body: some View {
        // 2.0 — Su açıksa ikinci sayfa (sola kaydır). Sayfalar yatay: dikey
        // olsaydı Digital Crown sayfa değiştirirdi, miktar ayarına gitmezdi.
        if model.water.enabled {
            TabView {
                creatinePage
                WatchWaterView()
            }
            .tabViewStyle(.page)
        } else {
            creatinePage
        }
    }

    private var creatinePage: some View {
        let t = model.today

        return Group {
            if !t.onboarded {
                Text(L.watchSetupFirst)
                    .font(.system(.body, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(soft)
                    .padding()
            } else if t.isTaken {
                taken(t)
            } else {
                ask(t)
            }
        }
        .animation(.snappy, value: t.isTaken)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refresh() }
        }
    }

    // MARK: - Soru

    private func ask(_ t: WatchModel.Today) -> some View {
        VStack(spacing: 8) {
            Text(L.todayQuestion)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(3)

            Button {
                model.log()
            } label: {
                Text(L.todayYes)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 10)
                    .frame(width: 92, height: 92)
                    .background(accent, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L.todayYesA11y)

            streakLine(t)
        }
    }

    // MARK: - Alındı

    private func taken(_ t: WatchModel.Today) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(accent)

            Text(L.widgetDoseLogged)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)

            streakLine(t)

            Button(L.todayUndo) { model.undo() }
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(soft)
                .buttonStyle(.plain)
                .padding(.top, 2)
        }
    }

    // MARK: - Seri

    @ViewBuilder
    private func streakLine(_ t: WatchModel.Today) -> some View {
        if t.streak > 1 {
            Text(L.todayStreak(t.streak))
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

// MARK: - Su (2.0)

/// Saatte su: bardak, toplam, Digital Crown ile miktar, "Ekle" ve geri al.
/// Kap simgelerine dokunmak miktarı o kaba ayarlar.
struct WatchWaterView: View {
    @EnvironmentObject private var model: WatchModel
    @State private var amount: Double = 250
    @State private var didSetInitial = false
    /// Sayfa açılınca Crown doğrudan miktarı çevirsin.
    @FocusState private var crownFocused: Bool
    /// Crown'un ham değeri. Miktara doğrudan bağlı değil: her tam adım
    /// (bir "tık") miktarı 50 ml değiştiriyor ve haptik veriyor.
    @State private var crown: Double = 0
    @State private var crownAnchor: Double = 0

    private let step = 50
    private let minAmount = 50
    private let maxAmount = 1500

    private let accent = Color(red: 0.36, green: 0.53, blue: 1.0)      // #5C86FF
    private let soft = Color(red: 0.58, green: 0.61, blue: 0.65)       // #939CA6
    private let gold = Color(red: 0.96, green: 0.77, blue: 0.26)       // #F4C542

    var body: some View {
        let w = model.water
        Group {
            if w.plus {
                content(w)
            } else {
                locked
            }
        }
        .onAppear {
            if !didSetInitial, let first = w.cups.first {
                amount = Double(first.ml)
                didSetInitial = true
            }
            crownFocused = true
        }
    }

    private func content(_ w: WatchModel.Water) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                ZStack {
                    GlassShape().fill(accent.opacity(0.15))
                    WaveFill(fraction: w.fraction, phase: Double(w.total) / 250 * .pi / 2)
                        .fill(accent)
                        .clipShape(GlassShape())
                    GlassShape().stroke(accent.opacity(0.4), lineWidth: 1.5)
                }
                .frame(width: 24, height: 34)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: w.total)

                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: "\(w.total.litersString) L")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .contentTransition(.numericText())
                    Text(verbatim: "/ \(w.goal.litersString) L")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(soft)
                }
                Spacer(minLength: 0)
            }

            // Crown ile 50 ml adımlarla; dokunulacak bir şey yok, sadece çevir.
            Text(verbatim: "\(Int(amount)) ml")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
                .focusable()
                .focused($crownFocused)
                .digitalCrownRotation($crown, from: -10_000, through: 10_000, by: 1,
                                      sensitivity: .medium, isContinuous: true,
                                      isHapticFeedbackEnabled: false)
                .onChange(of: crown) { _, new in crownMoved(to: new) }

            HStack(spacing: 6) {
                ForEach(w.cups) { cup in
                    Button { amount = Double(cup.ml) } label: {
                        CupIcon(kind: cup.kind)
                            .fill(Int(amount) == cup.ml ? .white : accent)
                            .frame(width: 13, height: 13)
                            .frame(width: 28, height: 28)
                            .background(Int(amount) == cup.ml ? accent : accent.opacity(0.18), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: "\(cup.kind.title), \(cup.ml) ml"))
                }
                Spacer(minLength: 0)
                Button { model.undoWater() } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(w.total > 0 ? .white : soft.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(w.total == 0)
                .accessibilityLabel(L.todayUndo)
            }

            Button { model.addWater(Int(amount)) } label: {
                Text(L.watchWaterAdd)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }

    /// Crown kaç tam adım döndüyse o kadar 50 ml; her adımda bir tık.
    /// Sınıra gelince haptik yok, değer taşmıyor.
    private func crownMoved(to value: Double) {
        let steps = Int((value - crownAnchor).rounded(.towardZero))
        guard steps != 0 else { return }
        crownAnchor += Double(steps)
        let direction = steps > 0 ? 1 : -1
        for _ in 0..<abs(steps) {
            let next = Int(amount) + direction * step
            guard next >= minAmount, next <= maxAmount else { break }
            amount = Double(next)
            WKInterfaceDevice.current().play(.click)
        }
    }

    private var locked: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(gold)
            (Text(verbatim: "OneScoop") + Text(verbatim: "+").foregroundStyle(gold))
                .font(.system(.headline, design: .rounded).weight(.heavy))
            Text(L.watchWaterPlus)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(soft)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
