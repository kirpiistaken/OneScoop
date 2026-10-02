import SwiftUI

// 2.1 — Paylaşım kartı (Instagram hikâyesi, 1080×1920). Rozet kazanınca ve
// rozet ekranından seri için. Kart doğrudan 1080×1920 noktada çiziliyor. Tasarım: tasarım sayfasındaki "Paylaşım kartı".

enum ShareCardKind {
    case badge(Badge, ribbon: String)
    case streak(days: Int, last28: [Bool])
}

struct ShareCardView: View {
    var kind: ShareCardKind

    /// Kart doğrudan 1080×1920 noktada çiziliyor (ölçek 1). Böylece parlama ve
    /// gölgeler de tam çözünürlükte hesaplanıyor, büyütülüp pikselleşmiyor.
    /// Tasarım 360×640 üzerinden; her ölçü k ile çarpılıyor.
    private let k: CGFloat = 3

    private var tint: Color {
        if case .badge(let b, _) = kind { return MedalPalette.of(b.tier).c1 }
        return Color(hex: 0x8FB0FF)
    }
    private var glow: Color {
        if case .badge(let b, _) = kind { return MedalPalette.of(b.tier).glow }
        return Color(hex: 0x5C86FF).opacity(0.45)
    }

    var body: some View {
        ZStack {
            Color(hex: 0x0A0F1F)
            // Bloom ve ışınlar rozetin/sayının arkasında
            RadialGradient(colors: [glow.opacity(0.95), glow.opacity(0.3), .clear],
                           center: .center, startRadius: 0, endRadius: 300 * k)
                .frame(width: 640 * k, height: 640 * k)
                .position(x: 180 * k, y: 250 * k)
            ShareRays(count: 18)
                .fill(AngularGradient(colors: [tint.opacity(0.14), tint.opacity(0.02), tint.opacity(0.14)],
                                      center: .center))
                .frame(width: 720 * k, height: 720 * k)
                .mask(RadialGradient(colors: [.white, .white.opacity(0.35), .clear],
                                     center: .center, startRadius: 30 * k, endRadius: 330 * k))
                .position(x: 180 * k, y: 250 * k)
            sparkles
            curves
            VStack(spacing: 0) {
                switch kind {
                case .badge(let badge, let ribbon):
                    badgeContent(badge, ribbon)
                case .streak(let days, let last28):
                    streakContent(days, last28)
                }
                Spacer(minLength: 0)
                footer
            }
            .padding(.top, 62 * k)
            .padding(.bottom, 46 * k)
        }
        .frame(width: 360 * k, height: 640 * k)
        .clipped()
        .environment(\.colorScheme, .dark)
    }

    private func badgeContent(_ badge: Badge, _ ribbon: String) -> some View {
        VStack(spacing: 0) {
            Text(L.shareNewBadge)
                .font(.system(size: 13 * k, weight: .black, design: .rounded))
                .tracking(3.4 * k)
                .foregroundStyle(tint)
            MedalView(badge: badge, ribbon: ribbon, width: 250 * k)
                .padding(.top, 22 * k)
            Text(verbatim: badge.name)
                .font(.system(size: 38 * k, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 22 * k)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(verbatim: badge.detail)
                .font(.system(size: 15 * k, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0xB9C3D8))
                .multilineTextAlignment(.center)
                .padding(.top, 8 * k)
                .padding(.horizontal, 30 * k)
        }
    }

    private func streakContent(_ days: Int, _ last28: [Bool]) -> some View {
        VStack(spacing: 0) {
            Text(L.shareStreakTitle)
                .font(.system(size: 13 * k, weight: .black, design: .rounded))
                .tracking(3.4 * k)
                .foregroundStyle(tint)
            Text(verbatim: "\(days)")
                .font(.system(size: 130 * k, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Color(hex: 0x8FB0FF).opacity(0.9), radius: 10 * k)
                .shadow(color: Color(hex: 0x5C86FF).opacity(0.6), radius: 30 * k)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 8 * k)
            Text(L.shareStreakDays)
                .font(.system(size: 21 * k, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(L.shareStreakTagline)
                .font(.system(size: 14 * k, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0xB9C3D8))
                .padding(.top, 6 * k)
            // Görsele çevrilirken tembel ızgaralar boş çıkabiliyor; düz yığın.
            VStack(spacing: 5 * k) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 5 * k) {
                        ForEach(0..<7, id: \.self) { col in
                            let i = row * 7 + col
                            let on = i < last28.count && last28[i]
                            RoundedRectangle(cornerRadius: 7 * k, style: .continuous)
                                .fill(on ? Color(hex: 0x5C86FF) : Color(hex: 0x1C2236))
                                .frame(width: 29 * k, height: 28 * k)
                                .shadow(color: on ? Color(hex: 0x5C86FF).opacity(0.45) : .clear, radius: 8 * k)
                        }
                    }
                }
            }
            .padding(.top, 36 * k)
            Text(L.shareLast4Weeks)
                .font(.system(size: 11 * k, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0x8A92A3))
                .padding(.top, 9 * k)
        }
    }

    private var footer: some View {
        VStack(spacing: 7 * k) {
            HStack(spacing: 7 * k) {
                ScoopShape()
                    .fill(.white)
                    .frame(width: 20 * k, height: 20 * k)
                    .frame(width: 30 * k, height: 30 * k)
                    .background(Color(hex: 0x3A66FF), in: RoundedRectangle(cornerRadius: 7 * k, style: .continuous))
                (Text(verbatim: "One") + Text(verbatim: "Scoop").foregroundColor(Color(hex: 0x5C86FF)))
                    .font(.system(size: 21 * k, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(L.shareFooter)
                .font(.system(size: 11 * k, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0x8A92A3))
        }
    }

    /// Sabit pırıltılar (paylaşılan görselde hareket yok).
    private var sparkles: some View {
        let spots: [(CGFloat, CGFloat, CGFloat)] = [
            (0.16, 0.20, 12), (0.84, 0.16, 9), (0.10, 0.42, 8), (0.90, 0.40, 14),
            (0.24, 0.58, 7), (0.78, 0.60, 10), (0.62, 0.10, 7), (0.38, 0.12, 6),
        ]
        return ZStack {
            ForEach(spots.indices, id: \.self) { i in
                let sp = spots[i]
                Image(systemName: "sparkle")
                    .font(.system(size: sp.2 * k, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: tint, radius: 5 * k)
                    .position(x: 360 * k * sp.0, y: 640 * k * sp.1)
            }
        }
        .frame(width: 360 * k, height: 640 * k)
    }

    private var curves: some View {
        Canvas { ctx, size in
            func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }
            var p1 = Path()
            p1.move(to: P(-20, 173))
            p1.addCurve(to: P(173, -27), control1: P(80, 127), control2: P(140, 40))
            var p2 = Path()
            p2.move(to: P(380, 500))
            p2.addCurve(to: P(213, 667), control1: P(287, 533), control2: P(233, 600))
            ctx.stroke(p1, with: .color(Color(hex: 0x3A66FF).opacity(0.35)), lineWidth: 1 * k)
            ctx.stroke(p2, with: .color(Color(hex: 0x3A66FF).opacity(0.35)), lineWidth: 1 * k)
        }
        .frame(width: 360 * k, height: 640 * k)
        .allowsHitTesting(false)
    }

    /// 1080×1920 görsel.
    @MainActor
    static func render(_ kind: ShareCardKind) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(kind: kind))
        renderer.scale = 1
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

/// Paylaşım kartındaki ışınlar.
struct ShareRays: Shape {
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

/// Kartı hazırlayıp paylaşma düğmesi.
struct ShareCardButton: View {
    var kind: ShareCardKind
    var title: String = L.shareButton
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview(Text(verbatim: "OneScoop"), image: Image(uiImage: image))
                ) {
                    label
                }
            } else {
                label.opacity(0.5)
            }
        }
        .task { image = ShareCardView.render(kind) }
    }

    private var label: some View {
        Label(title, systemImage: "square.and.arrow.up")
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(CT.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
