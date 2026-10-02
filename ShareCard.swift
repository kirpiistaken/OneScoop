import SwiftUI

// 2.1 — Paylaşım kartı (Instagram hikâyesi, 1080×1920). Rozet kazanınca ve
// rozet ekranından seri için. Kart 360×640 noktada çizilip 3x ölçekle
// görsele dönüştürülüyor. Tasarım: tasarım sayfasındaki "Paylaşım kartı".

enum ShareCardKind {
    case badge(Badge, ribbon: String)
    case streak(days: Int, last28: [Bool])
}

struct ShareCardView: View {
    var kind: ShareCardKind

    private var glow: Color {
        if case .badge(let b, _) = kind { return MedalPalette.of(b.tier).glow }
        return Color(hex: 0x5C86FF).opacity(0.3)
    }

    var body: some View {
        ZStack {
            Color(hex: 0x0A0F1F)
            RadialGradient(colors: [glow.opacity(0.6), .clear], center: UnitPoint(x: 0.5, y: 0.4),
                           startRadius: 0, endRadius: 300)
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
            .padding(.top, 70)
            .padding(.bottom, 50)
        }
        .frame(width: 360, height: 640)
        .environment(\.colorScheme, .dark)
    }

    private func badgeContent(_ badge: Badge, _ ribbon: String) -> some View {
        VStack(spacing: 0) {
            Text(L.shareNewBadge)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(3.4)
                .foregroundStyle(MedalPalette.of(badge.tier).c1)
            MedalView(badge: badge, ribbon: ribbon, width: 214)
                .padding(.top, 24)
            Text(verbatim: badge.name)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 22)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(verbatim: badge.detail)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0xB9C3D8))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 30)
        }
    }

    private func streakContent(_ days: Int, _ last28: [Bool]) -> some View {
        VStack(spacing: 0) {
            Text(L.shareStreakTitle)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(3.4)
                .foregroundStyle(Color(hex: 0x8FB0FF))
            Text(verbatim: "\(days)")
                .font(.system(size: 130, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Color(hex: 0x8FB0FF).opacity(0.9), radius: 10)
                .shadow(color: Color(hex: 0x5C86FF).opacity(0.6), radius: 30)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 8)
            Text(L.shareStreakDays)
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(L.shareStreakTagline)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0xB9C3D8))
                .padding(.top, 6)
            // Görsele çevrilirken tembel ızgaralar boş çıkabiliyor; düz yığın.
            VStack(spacing: 5) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 5) {
                        ForEach(0..<7, id: \.self) { col in
                            let i = row * 7 + col
                            let on = i < last28.count && last28[i]
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(on ? Color(hex: 0x5C86FF) : Color(hex: 0x1C2236))
                                .frame(width: 29, height: 28)
                                .shadow(color: on ? Color(hex: 0x5C86FF).opacity(0.45) : .clear, radius: 8)
                        }
                    }
                }
            }
            .padding(.top, 36)
            Text(L.shareLast4Weeks)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0x8A92A3))
                .padding(.top, 9)
        }
    }

    private var footer: some View {
        VStack(spacing: 7) {
            HStack(spacing: 7) {
                ScoopShape()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .frame(width: 30, height: 30)
                    .background(Color(hex: 0x3A66FF), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                (Text(verbatim: "One") + Text(verbatim: "Scoop").foregroundColor(Color(hex: 0x5C86FF)))
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(L.shareFooter)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0x8A92A3))
        }
    }

    private var curves: some View {
        Canvas { ctx, size in
            var p1 = Path()
            p1.move(to: CGPoint(x: -20, y: 173))
            p1.addCurve(to: CGPoint(x: 173, y: -27), control1: CGPoint(x: 80, y: 127), control2: CGPoint(x: 140, y: 40))
            var p2 = Path()
            p2.move(to: CGPoint(x: 380, y: 500))
            p2.addCurve(to: CGPoint(x: 213, y: 667), control1: CGPoint(x: 287, y: 533), control2: CGPoint(x: 233, y: 600))
            ctx.stroke(p1, with: .color(Color(hex: 0x3A66FF).opacity(0.35)), lineWidth: 1)
            ctx.stroke(p2, with: .color(Color(hex: 0x3A66FF).opacity(0.35)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }

    /// 1080×1920 görsel.
    @MainActor
    static func render(_ kind: ShareCardKind) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(kind: kind))
        renderer.scale = 3
        return renderer.uiImage
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
