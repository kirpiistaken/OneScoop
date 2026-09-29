import SwiftUI
import UIKit

// 2.0 — Su takibinin uygulama içi ekranları. Sadece uygulama target'ında.

extension WaterCup.Kind {
    var title: String {
        switch self {
        case .glass: L.waterCupGlass
        case .shaker: L.waterCupShaker
        case .bottle: L.waterCupBottle
        }
    }
}

// MARK: - Bardak görseli

/// Hedefe göre dolan, üstü hafif dalgalı bardak. Damla ikonu yok bilerek:
/// OneScoop'un kimliği kepçe, su onun yanında ikinci bir çizgi.
struct WaterGlass: View {
    var fraction: Double
    var wavePhase: Double = 0

    var body: some View {
        GeometryReader { geo in
            let shape = GlassShape()
            ZStack {
                shape.fill(CT.accent.opacity(0.10))
                WaveFill(fraction: fraction, phase: wavePhase)
                    .fill(CT.accent)
                    .clipShape(shape)
                shape.stroke(CT.accent.opacity(0.35), lineWidth: 2)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }
}

/// Aşağı doğru hafifçe daralan, köşeleri yuvarlak bardak.
struct GlassShape: Shape {
    func path(in r: CGRect) -> Path {
        let inset = r.width * 0.12
        let radius = r.width * 0.18
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - inset, y: r.maxY - radius))
        p.addQuadCurve(to: CGPoint(x: r.maxX - inset - radius, y: r.maxY),
                       control: CGPoint(x: r.maxX - inset, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + inset + radius, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX + inset, y: r.maxY - radius),
                       control: CGPoint(x: r.minX + inset, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct WaveFill: Shape {
    var fraction: Double
    var phase: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(fraction, phase) }
        set { fraction = newValue.first; phase = newValue.second }
    }

    func path(in r: CGRect) -> Path {
        let f = min(1, max(0, fraction))
        guard f > 0 else { return Path() }
        let level = r.maxY - r.height * f
        let amp = f >= 1 ? 0 : r.height * 0.025
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: level))
        let steps = 24
        for i in 0...steps {
            let x = r.minX + r.width * Double(i) / Double(steps)
            let y = level + amp * sin(Double(i) / Double(steps) * 2 * .pi + phase)
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Bugün ekranındaki su kartı

struct WaterCard: View {
    @EnvironmentObject private var store: CreatineStore
    @EnvironmentObject private var plus: PlusStore

    @State private var lastAdded: WaterEntry?
    @State private var hideUndo: Task<Void, Never>?
    @State private var wavePhase: Double = 0
    @State private var showEntries = false
    @State private var showPaywall = false

    private var total: Int { store.waterTotalToday }
    private var goal: Int { store.water.goalMl }
    private var fraction: Double { goal > 0 ? Double(total) / Double(goal) : 0 }

    var body: some View {
        HStack(spacing: 18) {
            WaterGlass(fraction: fraction, wavePhase: wavePhase)
                .frame(width: 54, height: 78)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fraction)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(L.waterTitle)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(CT.inkSoft)
                    Spacer()
                    Text(verbatim: "\(total.litersString) / \(goal.litersString) L")
                        .font(CT.display(20, .bold))
                        .foregroundStyle(CT.ink)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: total)
                }

                statusLine

                HStack(spacing: 8) {
                    addButton
                    cupsButton
                }
            }
        }
        .padding(16)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture { showEntries = true }
        .sheet(isPresented: $showEntries) { WaterEntriesSheet() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // Ekledikten sonra birkaç saniye "Geri al", sonra tempo satırı.
    @ViewBuilder
    private var statusLine: some View {
        if let last = lastAdded {
            Button {
                store.removeWater(last.id)
                lastAdded = nil
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            } label: {
                Text(L.waterAdded(String(last.ml)))
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(CT.accent)
            }
            .buttonStyle(.plain)
            .transition(.opacity)
        } else {
            Text(paceText)
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .foregroundStyle(CT.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .transition(.opacity)
        }
    }

    private var paceText: String {
        if total >= goal { return L.waterGoalReached }
        let behind = WaterData.expectedByNow(goal: goal) - total
        return behind > 150 ? L.waterPaceBehind(String(behind)) : L.waterPaceOn
    }

    private var addButton: some View {
        let cup = store.water.defaultCup
        return Button { add(cup.ml) } label: {
            Label {
                Text(verbatim: "+\(cup.ml) ml")
            } icon: {
                Image(systemName: cup.kind.symbol)
            }
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(CT.accent, in: Capsule())
        }
        .buttonStyle(PressableStyle())
    }

    @ViewBuilder
    private var cupsButton: some View {
        let label = Image(systemName: "ellipsis")
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(CT.accent)
            .frame(width: 36, height: 36)
            .background(CT.accent.opacity(0.12), in: Circle())

        if plus.isUnlocked {
            Menu {
                ForEach(store.water.cups) { cup in
                    if cup.offersPortions {
                        Menu {
                            portion(cup, 1.0, L.waterFull)
                            portion(cup, 0.75, "¾")
                            portion(cup, 0.5, "½")
                            portion(cup, 0.25, "¼")
                        } label: {
                            Label(cupTitle(cup), systemImage: cup.kind.symbol)
                        }
                    } else {
                        Button { add(cup.ml) } label: {
                            Label(cupTitle(cup), systemImage: cup.kind.symbol)
                        }
                    }
                }
            } label: { label }
        } else {
            Button { showPaywall = true } label: { label }
                .buttonStyle(.plain)
        }
    }

    private func portion(_ cup: WaterCup, _ share: Double, _ title: String) -> some View {
        let ml = Int((Double(cup.ml) * share).rounded())
        return Button { add(ml) } label: { Text(verbatim: "\(title) · \(ml) ml") }
    }

    private func cupTitle(_ cup: WaterCup) -> String {
        "\(cup.kind.title) · \(cup.ml) ml"
    }

    private func add(_ ml: Int) {
        let entry = store.addWater(ml)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.easeInOut(duration: 1.2)) { wavePhase += 2 * .pi }
        withAnimation(.snappy) { lastAdded = entry }
        hideUndo?.cancel()
        hideUndo = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) { lastAdded = nil }
        }
    }
}

// MARK: - Kreatin köprüsü

/// Kreatin kaydedildikten sonra: "Yanında bir bardak su? +250 ml".
struct CreatineWaterBridge: View {
    @EnvironmentObject private var store: CreatineStore

    var body: some View {
        let cup = store.water.defaultCup
        Button {
            store.addWater(cup.ml)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            Label(L.waterBridge(String(cup.ml)), systemImage: cup.kind.symbol)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(CT.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(CT.surface, in: Capsule())
        }
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Günün kayıtları

struct WaterEntriesSheet: View {
    @EnvironmentObject private var store: CreatineStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if store.waterToday.isEmpty {
                    Text(L.waterNoEntries)
                        .foregroundStyle(CT.inkSoft)
                } else {
                    ForEach(store.waterToday.reversed()) { entry in
                        HStack {
                            Text(entry.at, style: .time)
                                .foregroundStyle(CT.inkSoft)
                            Spacer()
                            Text(verbatim: "\(entry.ml) ml")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.removeWater(entry.id)
                            } label: {
                                Label(L.waterDelete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle(L.waterTodayEntries)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.commonDone) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - "Yeni: Su" tanıtımı (2.0 ilk açılış)

struct WaterIntroSheet: View {
    @EnvironmentObject private var store: CreatineStore
    @Environment(\.dismiss) private var dismiss
    @State private var fill = 0.15

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 8)
            WaterGlass(fraction: fill, wavePhase: fill * 10)
                .frame(width: 84, height: 120)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.6).delay(0.2)) { fill = 0.7 }
                }

            VStack(spacing: 10) {
                Text(L.whatsnewWaterTitle)
                    .font(CT.display(30, .heavy))
                    .foregroundStyle(CT.ink)
                    .multilineTextAlignment(.center)
                Text(L.whatsnewWaterBody)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 8)

            Button {
                store.updateWater {
                    $0.enabled = true
                    $0.hasSeenIntro = true
                }
                dismiss()
            } label: {
                Text(L.whatsnewWaterTry)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(CT.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PressableStyle())

            Button(L.plusNotNow) {
                store.updateWater { $0.hasSeenIntro = true }
                dismiss()
            }
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(CT.inkSoft)
        }
        .padding(24)
        .background(CT.bg.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled()
    }
}
