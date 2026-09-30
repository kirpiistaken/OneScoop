#!/usr/bin/env python3
"""
Denetim Merkezi düğmesi için özel SF Symbol üretir: uygulama logosundaki kepçe.

Denetim Merkezi kontrolleri sadece SF Symbol kabul ediyor; görsel ya da SwiftUI
şekli çizilmiyor. Bu betik kepçeyi logonun 1254 px'lik orijinal koordinatlarından
(saat kadranındaki ScoopShape ile aynı ölçüler) SF Symbols şablon biçiminde
SVG'ye döküyor.

İki simge:
  onescoop.scoop        — henüz alınmadı
  onescoop.scoop.check  — alındı: kepçenin gövdesinde tik şeklinde boşluk

Boolean işlemi kütüphanesi olmadan: dış kontur tek parça çiziliyor, delikler
ters yönde çizilip nonzero kuralıyla kesiliyor. Deliklerin hiçbiri başka bir
dolu parçayla örtüşmüyor, o yüzden sonuç doğru.
"""
import math, os, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "WidgetSymbols.xcassets")

CX, RX = 506.5, 250.5          # ağız, gövde ve dip aynı merkez ve genişlikte
N = 72                         # elips örnekleme sayısı

def arc(cx, cy, rx, ry, a0, a1, n):
    return [(cx + rx * math.cos(a0 + (a1 - a0) * i / n),
             cy + ry * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]

def silhouette():
    # sol ağız noktasından üstten sağa (ekran koordinatı: y aşağı)
    pts = arc(CX, 540, RX, 100, math.pi, 2 * math.pi, N)
    pts += [(CX + RX, 800)]
    pts += arc(CX, 800, RX, 125, 0, math.pi, N)[1:]
    pts += [(CX - RX, 540)]
    return pts

def hole():
    return arc(CX, 538, 221, 69, 0, 2 * math.pi, N)[:-1]

def handle(n=24):
    """Sap: gövdeye düz kenarla bağlanır, sadece dış ucu yuvarlak (logodaki gibi).
    Başlangıç noktaları ağız boşluğunun dışında kalıyor, boşlukla örtüşmüyor."""
    cx, cy, r = 1040.0, 395.0, 50.0
    a0 = math.atan2(349.44 - cy, 1019.40 - cx)
    a1 = math.atan2(440.56 - cy, 1060.60 - cx)
    pts = [(712.0, 488.45)]
    pts += [(cx + r * math.cos(a0 + (a1 - a0) * i / n), cy + r * math.sin(a0 + (a1 - a0) * i / n))
            for i in range(n + 1)]
    pts += [(745.0, 583.27), (750.0, 540.0)]
    return pts

def capsule(p0, p1, r, n=24):
    (x0, y0), (x1, y1) = p0, p1
    a = math.atan2(y1 - y0, x1 - x0)
    pts = arc(x1, y1, r, r, a - math.pi / 2, a + math.pi / 2, n)
    pts += arc(x0, y0, r, r, a + math.pi / 2, a + 3 * math.pi / 2, n)
    return pts

def check(a, b, c, w):
    """İki parçalı tik çizgisinin dış hattı (düz uçlu, köşede miter)."""
    def nrm(p, q):
        dx, dy = q[0] - p[0], q[1] - p[1]; L = math.hypot(dx, dy)
        return (-dy / L * w, dx / L * w)
    def add(p, n, s=1): return (p[0] + s * n[0], p[1] + s * n[1])
    def inter(p1, d1, p2, d2):
        det = d1[0] * d2[1] - d1[1] * d2[0]
        t = ((p2[0] - p1[0]) * d2[1] - (p2[1] - p1[1]) * d2[0]) / det
        return (p1[0] + t * d1[0], p1[1] + t * d1[1])
    n1, n2 = nrm(a, b), nrm(b, c)
    d1 = (b[0] - a[0], b[1] - a[1]); d2 = (c[0] - b[0], c[1] - b[1])
    j_pos = inter(add(a, n1), d1, add(b, n2), d2)
    j_neg = inter(add(a, n1, -1), d1, add(b, n2, -1), d2)
    return [add(a, n1), j_pos, add(c, n2), add(c, n2, -1), j_neg, add(a, n1, -1)]

def area(p):
    return sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1]
               for i in range(len(p))) / 2

def oriented(p, positive):
    return p if (area(p) > 0) == positive else p[::-1]

def parts(with_check):
    solid = [silhouette(), handle()]
    holes = [hole()]
    if with_check:
        holes.append(check((418, 742), (492, 816), (618, 676), 24))
    return ([oriented(s, True) for s in solid] +
            [oriented(h, False) for h in holes])

# Logo koordinatından simge koordinatına: taban çizgisi y=925, üst y=345
TOP, BASE, LEFT = 345.0, 925.0, 256.0
K = 70.0 / (BASE - TOP)
WIDTH = (1090 - LEFT) * K

def to_sym(p):
    return (round((p[0] - LEFT) * K, 3), round((p[1] - BASE) * K, 3))

def path_d(polys):
    out = []
    for poly in polys:
        pts = [to_sym(p) for p in poly]
        out.append("M" + " L".join(f"{x} {y}" for x, y in pts) + " Z")
    return " ".join(out)

# SF Symbols şablon v3: sistem Ultralight-S, Regular-S ve Black-S olmak üzere
# üç ana çizim bekliyor, diğer 24 kalınlık/boyutu bunlardan türetiyor. Tek
# çizim (sadece Regular-M) bırakınca şablon geçersiz sayılıp simge boş
# görünüyor. Kepçenin kalınlığı değişmesin diye üçüne de aynı çizim konuyor.
MASTERS = [("Ultralight-S", 560.0), ("Regular-S", 1390.0), ("Black-S", 2220.0)]
BASE_S = 696

TEMPLATE_HEAD = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<!--glyph: "{name}", point size: 100.0, template writer version: "OneScoop"-->
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="3300" height="2200">
 <g id="Notes">
  <rect height="2200" id="artboard" style="fill:white;opacity:1" width="3300" x="0" y="0"/>
  <line style="fill:none;stroke:black;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="292" y2="292"/>
  <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13;font-weight:bold;" transform="matrix(1 0 0 1 263 322)">Weight/Scale Variations</text>
  <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13;" transform="matrix(1 0 0 1 559.711 322)" text-anchor="middle">Ultralight</text>
  <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13;" transform="matrix(1 0 0 1 1389.9 322)" text-anchor="middle">Regular</text>
  <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13;" transform="matrix(1 0 0 1 2220.1 322)" text-anchor="middle">Black</text>
  <text id="template-version" style="stroke:none;fill:black;font-family:sans-serif;font-size:13;" transform="matrix(1 0 0 1 3036 1933)" text-anchor="end">Template v.3.0</text>
  <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13;" transform="matrix(1 0 0 1 3036 1951)" text-anchor="end">Requires Xcode 13 or greater</text>
 </g>
 <g id="Guides">
  <line id="Baseline-S" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="696" y2="696"/>
  <line id="Capline-S" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="625.541" y2="625.541"/>
  <line id="Baseline-M" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="1126" y2="1126"/>
  <line id="Capline-M" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="1055.54" y2="1055.54"/>
  <line id="Baseline-L" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="1556" y2="1556"/>
  <line id="Capline-L" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="1485.54" y2="1485.54"/>
{margins} </g>
 <g id="Symbols">
{symbols} </g>
</svg>
"""

MARGIN = '  <line id="{side}-margin-{m}" style="fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;" x1="{x}" x2="{x}" y1="600.785" y2="720.121"/>\n'
SYMBOL = '  <g id="{m}" transform="matrix(1 0 0 1 {x0} {base})">\n   <path d="{d}"/>\n  </g>\n'

def write(name, with_check):
    d = os.path.join(OUT, f"{name}.symbolset")
    os.makedirs(d, exist_ok=True)
    path = path_d(parts(with_check))
    margins = "".join(
        MARGIN.format(side="left", m=m, x=round(x0 - 3, 3)) +
        MARGIN.format(side="right", m=m, x=round(x0 + WIDTH + 3, 3))
        for m, x0 in MASTERS)
    symbols = "".join(SYMBOL.format(m=m, x0=x0, base=BASE_S, d=path) for m, x0 in MASTERS)
    svg = TEMPLATE_HEAD.format(name=name, margins=margins, symbols=symbols)
    open(os.path.join(d, f"{name}.svg"), "w").write(svg)
    open(os.path.join(d, "Contents.json"), "w").write(
        '{\n  "info" : { "author" : "xcode", "version" : 1 },\n'
        f'  "symbols" : [ {{ "filename" : "{name}.svg", "idiom" : "universal" }} ]\n}}\n')

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    open(os.path.join(OUT, "Contents.json"), "w").write(
        '{\n  "info" : { "author" : "xcode", "version" : 1 }\n}\n')
    write("onescoop.scoop", False)
    write("onescoop.scoop.check", True)
    print("width", round(WIDTH, 2), "height 70")
    if len(sys.argv) > 1:   # önizleme: python3 make_scoop_symbol.py out_dir
        from PIL import Image, ImageDraw
        for name, wc in (("plain", False), ("check", True)):
            S = 6
            img = Image.new("L", (int((WIDTH + 20) * S), 100 * S), 0)
            dr = ImageDraw.Draw(img)
            ps = parts(wc)
            # nonzero kuralını taklit: önce doluları, sonra delikleri çiz
            for p in ps:
                col = 255 if area(p) > 0 else 0
                pts = [((x + 10) * S, (y + 85) * S) for x, y in (to_sym(q) for q in p)]
                if col: dr.polygon(pts, fill=col)
            for p in ps:
                if area(p) <= 0:
                    pts = [((x + 10) * S, (y + 85) * S) for x, y in (to_sym(q) for q in p)]
                    dr.polygon(pts, fill=0)
            img.save(os.path.join(sys.argv[1], f"sym_{name}.png"))
