import SwiftUI

// 2.1 — Rozet madalyası: tırtıklı madalya, arkada kurdele uçları, ortada büyük
// dolu ikon, önde bant. Bantta sadece sayı; beyaz, hafif parlama ve seviyenin
// koyu tonunda ince kontur. Tasarım: design/2.1/Badges-Medal.dc.html
//
// Çizim 200×220'lik bir alanda tanımlı, verilen genişliğe ölçekleniyor.

struct MedalPalette {
    let c1: Color, c2: Color, c3: Color, i1: Color, i2: Color, glow: Color

    static func of(_ tier: BadgeTier, locked: Bool = false) -> MedalPalette {
        if locked {
            return MedalPalette(c1: Color(hex: 0x4A505D), c2: Color(hex: 0x2A2F3A), c3: Color(hex: 0x22262F),
                                i1: Color(hex: 0x6A7080), i2: Color(hex: 0x4A505D), glow: .clear)
        }
        switch tier {
        case .bronze:
            return MedalPalette(c1: Color(hex: 0xF0B88A), c2: Color(hex: 0x9A5A34), c3: Color(hex: 0x6E3C20),
                                i1: Color(hex: 0xFFD7B5), i2: Color(hex: 0xD08A58), glow: Color(hex: 0xE8A06E).opacity(0.35))
        case .silver:
            return MedalPalette(c1: Color(hex: 0xF6F8FB), c2: Color(hex: 0x9AA2B3), c3: Color(hex: 0x5F6778),
                                i1: .white, i2: Color(hex: 0xAEB6C6), glow: Color(hex: 0xDCE2EC).opacity(0.3))
        case .gold:
            return MedalPalette(c1: Color(hex: 0xFFE79A), c2: Color(hex: 0xC88E1C), c3: Color(hex: 0x8A5E0E),
                                i1: Color(hex: 0xFFF0B8), i2: Color(hex: 0xE8B033), glow: Color(hex: 0xFFCD50).opacity(0.45))
        case .blue:
            return MedalPalette(c1: Color(hex: 0xC9E6FF), c2: Color(hex: 0x4F78F0), c3: Color(hex: 0x2C4BB8),
                                i1: Color(hex: 0xE6F3FF), i2: Color(hex: 0x7FA4FF), glow: Color(hex: 0x5C86FF).opacity(0.55))
        }
    }
}

extension Color {
    init(hex: UInt32) { self.init(uiColor: UIColor(hex: hex)) }
}

struct MedalView: View {
    var badge: Badge
    var ribbon: String
    var locked: Bool = false
    var width: CGFloat = 120
    /// Paylaşım kartı gibi büyük kullanımlarda arkadaki ışık.
    var glows: Bool = true

    private var p: MedalPalette { MedalPalette.of(badge.tier, locked: locked) }
    private var s: CGFloat { width / 200 }

    var body: some View {
        let metal = LinearGradient(colors: [p.c1, p.c2], startPoint: .topLeading, endPoint: .bottomTrailing)
        let iconFill = LinearGradient(colors: [p.i1, p.i2], startPoint: .top, endPoint: .bottom)

        ZStack(alignment: .topLeading) {
            // Kurdele uçları
            Poly(points: [(64, 128), (46, 214), (66, 202), (82, 216), (96, 140)]).fill(p.c3)
            Poly(points: [(136, 128), (154, 214), (134, 202), (118, 216), (104, 140)]).fill(p.c3)

            // Tırtıklı madalya
            Scallop().fill(metal)
            Circ(cx: 100, cy: 96, r: 70).stroke(p.c3.opacity(0.6), lineWidth: 3 * s)
            Circ(cx: 100, cy: 96, r: 62).fill(Color(hex: 0x131722))

            // İkon
            icon(iconFill)
                .frame(width: 76 * s, height: 76 * s)
                .offset(x: 62 * s, y: 50 * s)

            // Bant
            Banner().fill(metal)
            Poly(points: [(14, 134), (186, 134)]).stroke(.white.opacity(0.4), lineWidth: 1.5 * s)

            ribbonText
                .frame(width: width, height: 34 * s)
                .offset(y: 134 * s)
        }
        .frame(width: width, height: 220 * s)
        .shadow(color: glows ? p.glow : .clear, radius: 12 * s, y: 5 * s)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: badge.name))
    }

    @ViewBuilder
    private func icon(_ fill: LinearGradient) -> some View {
        switch badge.glyph {
        case .scoop:
            ScoopShape().fill(fill)
        default:
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .fontWeight(.bold)
                .foregroundStyle(fill)
                .padding(4 * s)
        }
    }

    private var symbol: String {
        switch badge.glyph {
        case .scoop: "circle"
        case .drop: "drop.fill"
        case .star: "star.fill"
        case .bolt: "bolt.fill"
        case .box: "shippingbox.fill"
        case .calendar: "calendar"
        }
    }

    /// Beyaz sayı, hafif parlama, seviye renginde ince kontur. Kontur 8 yöne
    /// kaydırılmış keskin kopyalarla, parlama bulanık bir kopyayla çiziliyor;
    /// gölge tabanlı çizim görsele çevrilirken pikselleşiyordu.
    private var ribbonText: some View {
        let o = max(0.7, 1.1 * s)
        let base = Text(verbatim: ribbon)
            .font(.system(size: 26 * s, weight: .black, design: .rounded))
        return ZStack {
            if !locked {
                base.foregroundStyle(.white.opacity(0.85)).blur(radius: 5 * s)
                base.foregroundStyle(.white.opacity(0.5)).blur(radius: 12 * s)
            }
            ForEach(0..<8, id: \.self) { i in
                let a = Double(i) * .pi / 4
                base.foregroundStyle(p.c3)
                    .offset(x: CGFloat(cos(a)) * o, y: CGFloat(sin(a)) * o)
            }
            base.foregroundStyle(.white)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .padding(.horizontal, 30 * s)
    }

    // MARK: Şekiller (200×220 alanında)

    private struct Poly: Shape {
        var points: [(CGFloat, CGFloat)]
        func path(in r: CGRect) -> Path {
            let k = r.width / 200
            var path = Path()
            for (i, pt) in points.enumerated() {
                let c = CGPoint(x: pt.0 * k, y: pt.1 * k)
                if i == 0 { path.move(to: c) } else { path.addLine(to: c) }
            }
            if points.count > 2 { path.closeSubpath() }
            return path
        }
    }

    private struct Circ: Shape {
        var cx: CGFloat, cy: CGFloat, r: CGFloat
        func path(in rect: CGRect) -> Path {
            let k = rect.width / 200
            return Path(ellipseIn: CGRect(x: (cx - r) * k, y: (cy - r) * k, width: 2 * r * k, height: 2 * r * k))
        }
    }

    private struct Scallop: Shape {
        func path(in rect: CGRect) -> Path {
            let k = rect.width / 200
            var path = Path()
            let n = 32
            for i in 0..<(n * 2) {
                let r: CGFloat = i % 2 == 0 ? 86 : 79
                let a = CGFloat.pi * CGFloat(i) / CGFloat(n) - .pi / 2
                let pt = CGPoint(x: (100 + r * cos(a)) * k, y: (96 + r * sin(a)) * k)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            return path
        }
    }

    private struct Banner: Shape {
        func path(in rect: CGRect) -> Path {
            Poly(points: [(14, 134), (186, 134), (173, 151), (186, 168), (14, 168), (27, 151)]).path(in: rect)
        }
    }
}
