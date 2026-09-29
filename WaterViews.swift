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

// MARK: - Kap simgeleri

/// Bardak, shaker ve şişe için kendi çizimlerimiz. SF Symbols'da sade bir su
/// bardağı ya da shaker yok; üçü aynı çizgide ve birbirinden net ayrılsın diye.
struct CupIcon: Shape {
    var kind: WaterCup.Kind

    /// En-boy oranı (genişlik / yükseklik).
    var aspect: CGFloat {
        switch kind {
        case .glass: 0.78
        case .shaker: 0.72
        case .bottle: 0.62
        }
    }

    func path(in rect: CGRect) -> Path {
        let h = rect.height
        let w = h * aspect
        var p: Path
        switch kind {
        case .glass: p = GlassShape().path(in: CGRect(x: 0, y: 0, width: w, height: h))
        case .shaker: p = Self.shaker(w, h)
        case .bottle: p = Self.bottle(w, h)
        }
        return p.offsetBy(dx: rect.midX - w / 2, dy: rect.minY)
    }

    private static func rounded(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, _ r: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0), cornerRadius: r)
    }

    /// Alttan yuvarlatılmış gövde.
    private static func body(_ x0: CGFloat, _ top: CGFloat, _ x1: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: x0, y: top))
        p.addLine(to: CGPoint(x: x1, y: top))
        p.addLine(to: CGPoint(x: x1, y: h - r))
        p.addQuadCurve(to: CGPoint(x: x1 - r, y: h), control: CGPoint(x: x1, y: h))
        p.addLine(to: CGPoint(x: x0 + r, y: h))
        p.addQuadCurve(to: CGPoint(x: x0, y: h - r), control: CGPoint(x: x0, y: h))
        p.closeSubpath()
        return p
    }

    private static func shaker(_ w: CGFloat, _ h: CGFloat) -> Path {
        var p = Path()
        p.addPath(rounded(w * 0.20, 0, w * 0.44, h * 0.14, w * 0.05))          // kapakçık
        p.addPath(rounded(w * 0.06, h * 0.11, w * 0.94, h * 0.27, w * 0.06))   // kapak
        p.addPath(body(w * 0.12, h * 0.31, w * 0.88, h, w * 0.16))             // gövde
        return p
    }

    private static func bottle(_ w: CGFloat, _ h: CGFloat) -> Path {
        var p = Path()
        p.addPath(rounded(w * 0.33, 0, w * 0.67, h * 0.12, w * 0.04))          // kapak
        let x0 = w * 0.12, x1 = w * 0.88, nx0 = w * 0.37, nx1 = w * 0.63
        let r = w * 0.16, shoulder = h * 0.32
        var b = Path()
        b.move(to: CGPoint(x: nx0, y: h * 0.15))
        b.addLine(to: CGPoint(x: nx1, y: h * 0.15))
        b.addLine(to: CGPoint(x: nx1, y: h * 0.20))
        b.addQuadCurve(to: CGPoint(x: x1, y: shoulder), control: CGPoint(x: x1, y: h * 0.23))
        b.addLine(to: CGPoint(x: x1, y: h - r))
        b.addQuadCurve(to: CGPoint(x: x1 - r, y: h), control: CGPoint(x: x1, y: h))
        b.addLine(to: CGPoint(x: x0 + r, y: h))
        b.addQuadCurve(to: CGPoint(x: x0, y: h - r), control: CGPoint(x: x0, y: h))
        b.addLine(to: CGPoint(x: x0, y: shoulder))
        b.addQuadCurve(to: CGPoint(x: nx0, y: h * 0.20), control: CGPoint(x: x0, y: h * 0.23))
        b.closeSubpath()
        p.addPath(b)
        return p
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
        let inset = r.width * 0.14
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

/// Üstte bardak + toplam + tempo; altta üç kap butonu ve geri al.
/// Kaba dokun = o kap kadar eklenir. Geri al her basışta en son kaydı siler.
struct WaterCard: View {
    @EnvironmentObject private var store: CreatineStore
    @EnvironmentObject private var plus: PlusStore

    @State private var wavePhase: Double = 0
    @State private var showEntries = false

    private var total: Int { store.waterTotalToday }
    private var goal: Int { store.water.goalMl }
    private var fraction: Double { goal > 0 ? Double(total) / Double(goal) : 0 }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                WaterGlass(fraction: fraction, wavePhase: wavePhase)
                    .frame(width: 42, height: 60)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fraction)

                VStack(alignment: .leading, spacing: 4) {
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
                    Text(paceText)
                        .font(.system(.footnote, design: .rounded).weight(.medium))
                        .foregroundStyle(CT.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { showEntries = true }

            HStack(alignment: .top, spacing: 14) {
                // Ücretsizde sadece varsayılan kap; üç kap OneScoop+ ile.
                ForEach(plus.isUnlocked ? store.water.cups : [store.water.defaultCup]) { cup in
                    CupButton(cup: cup) { add(cup.ml) }
                }
                Spacer(minLength: 0)
                undoButton
            }
        }
        .padding(16)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .sheet(isPresented: $showEntries) { WaterEntriesSheet() }
    }

    private var paceText: String {
        if total >= goal { return L.waterGoalReached }
        let behind = WaterData.expectedByNow(goal: goal) - total
        return behind > 150 ? L.waterPaceBehind(String(behind)) : L.waterPaceOn
    }

    /// Her basış en son girilen suyu siler; art arda basılabilir.
    private var undoButton: some View {
        let canUndo = !store.waterToday.isEmpty
        return Button {
            store.undoLastWater()
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(canUndo ? CT.ink : CT.inkSoft.opacity(0.4))
                .frame(width: 44, height: 44)
                .background(CT.bg, in: Circle())
                .overlay(Circle().stroke(CT.hairline, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
        .disabled(!canUndo)
        .padding(.top, 7)          // kap dairelerinin ortasına hizalı
        .accessibilityLabel(L.todayUndo)
    }

    private func add(_ ml: Int) {
        store.addWater(ml)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.easeInOut(duration: 1.2)) { wavePhase += 2 * .pi }
    }
}

/// Yuvarlak kap butonu: simge + altında hacmi.
struct CupButton: View {
    var cup: WaterCup
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                CupIcon(kind: cup.kind)
                    .fill(CT.accent)
                    .frame(width: 30, height: 28)
                    .frame(width: 58, height: 58)
                    .background(CT.accent.opacity(0.14), in: Circle())
                Text(verbatim: "\(cup.ml) ml")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(CT.inkSoft)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(verbatim: "\(cup.kind.title), \(cup.ml) ml"))
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
            Label {
                Text(L.waterBridge(String(cup.ml)))
            } icon: {
                CupIcon(kind: cup.kind).fill(CT.accent).frame(width: 16, height: 16)
            }
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
                            .tint(.red)
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
                .frame(width: 70, height: 100)
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
                    .fixedSize(horizontal: false, vertical: true)
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
        .presentationDetents([.fraction(0.68), .large])
        .interactiveDismissDisabled()
    }
}
