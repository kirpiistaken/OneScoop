import SwiftUI

// Uygulama ve widget (renkler Theme.swift'ten).

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
