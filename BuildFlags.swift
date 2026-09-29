import Foundation

/// Derlemeye göre değişen ayarlar.
///
/// `testPurchaseEnabled`: TestFlight'ta ödemesiz test satın alması ve
/// Ayarlar'daki Test bölümü. Burada her zaman `false` durur; Codemagic sadece
/// `dev` dalını derlerken bunu `true` yapıyor (codemagic.yaml → "Dev build
/// ayarları"). Böylece `main`'den çıkan, review'a gidecek build'de satın alma
/// yalnızca gerçek StoreKit ile çalışıyor.
enum BuildFlags {
    static let testPurchaseEnabled = false
}
