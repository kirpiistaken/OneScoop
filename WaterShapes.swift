import SwiftUI

// 2.0 — Su çizimleri (saf şekiller). Uygulama, widget ve saat ortak kullanıyor.

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
