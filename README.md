# PersonelApp2 - Personel, Nöbet, Alışveriş ve Borç Yönetim Sistemi

Proje, personel takibi, nöbet matrisi, günlük raporlama, **Alışveriş (Kantin/Sepet)** ve **Borç Yönetimi (Taksitlendirme & Çevrimdışı Senkronizasyon)** modüllerini içeren modern bir Flutter uygulamasıdır.

---

## 🌟 Öne Çıkan Özellikler ve Modüller

1. **Alışveriş & Kantin Modülü (`lib/features/shopping`)**:
   - Ürün kataloğu, stok kontrolleri, indirim uygulama.
   - Sepet yönetimi (`CartNotifier` - Riverpod) ve ödeme (checkout) süreçleri.
   - Tip güvenli immutable veri modelleri (`ShoppingProduct`, `CartItem`).

2. **Borç Yönetimi & Taksitlendirme Modülü (`lib/features/debt`)**:
   - Borç kaydı oluşturma, otomatik taksit planlama.
   - Taksit ödemeleri, kalan bakiye ve durum takibi (`active`, `paid`, `overdue`).
   - **Çevrimdışı Senkronizasyon (`OfflineSyncService`)**: İnternet bağlantısı koptuğunda işlemleri yerelde kuyruklama, bağlantı sağlandığında arka planda otomatik senkronizasyon ve race-condition kilit mekanizması.

3. **Personel & Nöbet Matrisi**:
   - Personel liste yönetimi, arama, filtreleme, yedekleme.
   - Aylık nöbet matrisi, Vardiya & Temgundrap çizelgeleri.

---

## 🧪 Kapsamlı Test Mimarısı (%95+ Target Coverage)

Proje; Unit, Widget, Flutter Driver / Integration Test ve Mocking katmanlarına ayrılmıştır.

```
test/
├── mocks/                      # Mockito ile otomatik üretilen bağımlılık izolasyonları
│   ├── mock_annotations.dart
│   └── mock_annotations.mocks.dart
├── unit/                       # Birim testleri (Stok, Taksit, Sync, Race Condition)
│   └── features/
│       ├── debt/
│       └── shopping/
└── widget/                     # Widget rendering ve arayüz etkileşim testleri
    └── features/

integration_test/              # Canlı Cihaz / Emülatör Uçtan Uca (E2E) Testleri
├── shopping_user_journey_test.dart
├── debt_user_journey_test.dart
└── offline_sync_user_journey_test.dart
```

### Testleri Çalıştırma:
- **Tüm Statik Analiz & Testler**: `.\scripts\test_runner.bat`
- **Birim & Widget Testleri (Coverage ile)**: `flutter test --coverage test/unit test/widget`
- **Cihaz Üzerinde Entegrasyon Testleri**: `flutter test integration_test`
- **Çalışma Alanı Temizliği**: `.\scripts\clean_workspace.bat`

---

## ⚙️ CI/CD Pipeline (GitHub Actions)

Workflow dosyası: [.github/workflows/flutter_test_ci.yml](file:///c:/Users/baba/personelapp2/.github/workflows/flutter_test_ci.yml)

`main` dalına push yapıldığında CI pipeline'ı otomatik olarak:
1. `flutter analyze` ile statik analizi doğrular.
2. 127+ birim ve widget testini kapsama oranıyla çalıştırır.
3. Entegrasyon test suite'ini doğrular.
4. Release APK (`app-release.apk`) paketini derler.
5. Derlenen APK ve test raporlarını **3 gün otomatik saklama süresi (retention-days: 3)** ile çıktı verir ve çalışma alanını temizler.
