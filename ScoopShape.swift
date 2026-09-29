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

        let handle = Path { p in
            p.move(to: pt(768, 518))
            p.addLine(to: pt(1040, 395))
        }
        .strokedPath(StrokeStyle(lineWidth: 100 * s, lineCap: .round))

        var scoop = rim.union(body).union(bottom)
            .subtracting(hole)
            .union(handle)

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
