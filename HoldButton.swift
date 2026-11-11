import SwiftUI
import UIKit

// 2.1.2 — Basılı tutarak kaydet.
//
// Kaydırırken ya da yanlışlıkla dokunmayla kayıt girilmesin diye kayıt
// butonları kısa bir basılı tutma istiyor (kilit ekranındaki fener tuşu gibi):
// - parmak değince hafif bir tık ve buton içeri gömülüyor
// - basılı tutarken halka doluyor
// - halka dolunca sert "klik" ve kayıt
// - erken bırakılırsa hiçbir şey olmuyor, kısa bir "Basılı tut" ipucu çıkıyor
// - parmak kayarsa (kaydırma) iptal

struct HoldButton<Label: View>: View {
    var duration: Double = 0.4
    var action: () -> Void
    /// Etiket, dolum oranını (0…1) alıp halkayı kendisi çiziyor.
    @ViewBuilder var label: (CGFloat) -> Label

    @State private var progress: CGFloat = 0
    @State private var pressing = false
    @State private var pressStart: Date?
    @State private var showHint = false
    @State private var hintTask: Task<Void, Never>?

    private let touch = UIImpactFeedbackGenerator(style: .light)
    private let click = UIImpactFeedbackGenerator(style: .rigid)

    var body: some View {
        label(progress)
            .scaleEffect(pressing ? 0.92 : 1)
            .brightness(pressing ? -0.04 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: pressing)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: duration, maximumDistance: 12) {
                click.impactOccurred(intensity: 1)
                action()
                withAnimation(.easeOut(duration: 0.25).delay(0.1)) { progress = 0 }
            } onPressingChanged: { isPressing in
                pressing = isPressing
                if isPressing {
                    pressStart = Date()
                    touch.impactOccurred(intensity: 0.55)
                    click.prepare()
                    withAnimation(.linear(duration: duration)) { progress = 1 }
                } else {
                    // Tamamlanınca da "bırakıldı" geliyor (bazen perform'dan önce):
                    // süre dolduysa bu tamamlanmadır, dokunma.
                    let held = pressStart.map { Date().timeIntervalSince($0) } ?? 0
                    pressStart = nil
                    guard held < duration - 0.03 else { return }
                    // Erken bırakıldı ya da kaydırıldı: geri sar, ipucu göster.
                    withAnimation(.easeOut(duration: 0.18)) { progress = 0 }
                    flashHint()
                }
            }
            .overlay(alignment: .bottom) {
                if showHint {
                    Text(L.holdHint)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.75), in: Capsule())
                        .fixedSize()
                        .offset(y: 34)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .allowsHitTesting(false)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }   // VoiceOver: çift dokunuş yeter
    }

    private func flashHint() {
        hintTask?.cancel()
        withAnimation(.snappy) { showHint = true }
        hintTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) { showHint = false }
        }
    }
}
