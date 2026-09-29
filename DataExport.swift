import SwiftUI
import UIKit

// 2.0 — Verini dışa aktar (OneScoop+). Sadece uygulama target'ında.
// Tek bir CSV: kreatin ve su kayıtları, tarih ve saatle. Excel, Numbers ve
// Google E-Tablolar doğrudan açabiliyor.

enum DataExport {
    static func makeCSV(now: Date = Date()) -> URL? {
        let posix = Locale(identifier: "en_US_POSIX")
        let day = DateFormatter()
        day.locale = posix
        day.dateFormat = "yyyy-MM-dd"
        let time = DateFormatter()
        time.locale = posix
        time.dateFormat = "HH:mm"

        var rows: [(Date, String)] = []

        for entry in Persistence.loadLog().values {
            let grams = entry.grams == entry.grams.rounded()
                ? String(Int(entry.grams)) : String(format: "%.1f", entry.grams)
            rows.append((entry.takenAt,
                         "creatine,\(entry.day),\(time.string(from: entry.takenAt)),\(grams),g,onescoop"))
        }

        for list in WaterData.mergedLog().values {
            for e in list {
                let source = e.isFromHealth ? "apple_health" : "onescoop"
                rows.append((e.at, "water,\(day.string(from: e.at)),\(time.string(from: e.at)),\(e.ml),ml,\(source)"))
            }
        }

        let csv = (["type,date,time,amount,unit,source"] + rows.sorted { $0.0 < $1.0 }.map(\.1))
            .joined(separator: "\n") + "\n"

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("OneScoop-\(day.string(from: now)).csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

struct ExportFile: Identifiable {
    let url: URL
    var id: String { url.path }
}

/// Paylaşım sayfası (Dosyalar'a kaydet, AirDrop, Mail…).
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
