import SwiftUI

/// Uygulama logosundaki kepçe, vektör olarak çizilmiş. Koordinatlar logonun
/// 1254 piksellik orijinalinden alındı.
///
/// Görsel dosyası yerine şekil kullanılıyor: widget'lar ve saat kadranları
/// görsel yüklemede titiz, şekil ise her boyutta keskin kalıyor ve bulunduğu
/// yerin rengine (kilit ekranı, saat kadranı) göre boyanıyor.
///
/// Kullanıldığı yerler: iPhone kilit ekranı widget'ı, saat kadranı göstergesi.
/// (Denetim Merkezi şekil kabul etmiyor; orası için aynı çizim
/// tools/make_scoop_symbol.py ile SF Symbol olarak üretiliyor.)
struct ScoopShape: Shape {
    /// `true` ise gövdenin içinde tik şeklinde boşluk açılır ("alındı").
    var check: Bool = false

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 870
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.midX + (x - 672) * s, y: rect.midY + (y - 635) * s)
        }
        func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
            let o = pt(cx - rx, cy - ry)
            return Path(ellipseIn: CGRect(x: o.x, y: o.y, width: rx * 2 * s, height: ry * 2 * s))
        }

        let rim = ellipse(507, 540, 253, 100)                 // ağız dış halkası
        let o = pt(256, 540)
        let body = Path(CGRect(x: o.x, y: o.y, width: 501 * s, height: 260 * s))
        let bottom = ellipse(506.5, 800, 250.5, 125)          // yuvarlak dip
        let hole = ellipse(507, 538, 221, 69)                 // ağız iç boşluğu

        // Sap: logodaki gibi gövdeye düz kenarla bağlanıyor, sadece dış ucu
        // yuvarlak (merkez 1040,395, yarıçap 50). Eskiden uçları yuvarlak kalın
        // bir çizgiydi; gövde tarafındaki yuvarlak ağız boşluğuna taşıyordu.
        let handle = Path { p in
            p.move(to: pt(712, 488.45))            // üst kenar, ağzın dış halkasında
            p.addLine(to: pt(1019.40, 349.44))     // üst kenar, uca teğet
            let a0 = atan2(349.44 - 395, 1019.40 - 1040)
            let a1 = atan2(440.56 - 395, 1060.60 - 1040)
            for i in 1...24 {                      // dış uçtaki yarım daire
                let a = a0 + (a1 - a0) * CGFloat(i) / 24
                p.addLine(to: pt(1040 + 50 * cos(a), 395 + 50 * sin(a)))
            }
            p.addLine(to: pt(745, 583.27))         // alt kenar, gövdenin içinde
            p.addLine(to: pt(750, 540))
            p.closeSubpath()
        }

        // Ağız boşluğu en son kesiliyor: hiçbir parça ağzın içine taşmasın.
        var scoop = rim.union(body).union(bottom).union(handle)
            .subtracting(hole)

        if check {
            let tick = Path { p in
                p.move(to: pt(418, 742))
                p.addLine(to: pt(492, 816))
                p.addLine(to: pt(618, 676))
            }
            .strokedPath(StrokeStyle(lineWidth: 48 * s, lineCap: .round, lineJoin: .round))
            scoop = scoop.subtracting(tick)
        }
        return scoop
    }
}
