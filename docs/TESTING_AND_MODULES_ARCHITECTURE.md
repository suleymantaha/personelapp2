# PersonelApp2 - Mimari, Modüller ve Test Suite Dökümantasyonu

Bu doküman, projeye eklenen **Alışveriş (Kantin/Sepet)**, **Borç Yönetimi (Taksitlendirme & Çevrimdışı Senkronizasyon)** modüllerini, bağımlılık izolasyon sistemini (Mocking), Unit/Widget/Integration test suite'ini ve CI/CD pipeline yapılandırmasını detaylandırmaktadır.

---

## 📁 Proje Dosya Yapısı ve Değişiklik Nedenleri

### 1. Çekirdek Servisler (Core Services & Isolation)
- **`lib/core/network/api_client.dart`**: REST HTTP metotlarını (`get`, `post`, `put`, `delete`) ve ağ bağlantı durum kontrolünü (`isNetworkConnected`) soyutlar. Testlerde sunucu bağımlılığını ortadan kaldırır.
- **`lib/core/storage/local_storage_service.dart`**: Anahtar-değer ve liste depolama işlemlerini soyutlar. Test ortamında `InMemoryLocalStorageService` kullanılarak SQLite/SharedPreferences bağımlılığı olmadan hızlı test yapılmasını sağlar.
- **`lib/core/navigation/navigation_service.dart`**: Ekran geçişlerini soyutlayarak UI testlerinde sayfa yönlendirmelerini doğrulamaya imkan tanır.

---

### 2. Alışveriş & Kantin Modülü (`lib/features/shopping`)
- **`domain/shopping_models.dart`**: `ShoppingProduct` ve `CartItem` immutable modelleri. Fiyat, stok, kategori ve sepet ara toplam (subtotal) hesaplamalarını içerir.
- **`data/shopping_repository.dart`**: Ürün listesini getirme, sepeti yerel depolamaya kaydetme/yükleme ve ödeme (checkout) işlemlerini yürüten Clean Architecture veri katmanıdır.
- **`presentation/providers/cart_notifier.dart`**: Sepete ekleme, stok limiti kontrolü, miktar güncelleme, % indirim uygulama ve sepeti temizleme iş mantığını yöneten Riverpod `StateNotifier` sınıfıdır.
- **`presentation/shopping_screen.dart`**: Ürün kataloğu, sepet rozeti (badge) ve sepet detay alt ekranını (BottomSheet) sunan UI widget'ıdır. `ValueKey` nesneleri ile Flutter Driver test otomasyonuna uygun hale getirilmiştir. Tıklama çakışmalarını önlemek için badge alanı `IgnorePointer` ile sarılmıştır.

---

### 3. Borç Yönetimi & Taksitlendirme Modülü (`lib/features/debt`)
- **`domain/debt_models.dart`**: `DebtItem`, `InstallmentPlan` modelleri ve `DebtStatus` (active, paid, overdue) enum'u. Taksit tutarları, son ödeme tarihleri ve ödenme durumlarını temsil eder.
- **`data/debt_repository.dart`**: Yeni borç oluşturma, otomatik eşit taksit bölme, taksit ödeme ve kalan bakiye güncelleme metotlarını barındırır.
- **`services/offline_sync_service.dart`**: Çevrimdışı yapılan borç işlemlerini internet sağlandığında sunucuya iletir. Aynı anda birden fazla senkronizasyon tetiklenmesini önleyen mutex kilit mekanizmasına (`_isSyncing`) sahiptir.
- **`presentation/providers/debt_notifier.dart`**: Borçları yükleme, filtreleme (Aktif, Ödenen, Tümü), borç ekleme, taksit ödeme ve senkronizasyon tetikleme durumlarını yönetir.
- **`presentation/debt_management_screen.dart`**: Özet alacak/kalan bakiye kartları, borç listesi, taksit detayları ve borç oluşturma diyalog arayüzüdür.

---

### 4. Bağımlılık İzolasyonu & Mocking Layer
- **`test/mocks/mock_annotations.dart`**: `@GenerateNiceMocks` anotasyonu ile `ApiClient`, `LocalStorageService`, `NavigationService`, `ShoppingRepository`, `DebtRepository` ve `OfflineSyncService` sınıflarının sahte (mock) implementasyonlarını üretir.
- **`test/mocks/mock_annotations.mocks.dart`**: `build_runner` tarafından üretilen ve tüm birim/widget testlerinde kullanılan tam tip güvenli mock sınıflarını içerir.

---

### 5. Test Suite Yapısı

#### Birim (Unit) Testleri (`test/unit/...`):
- **`cart_notifier_test.dart`**: Sepete ekleme, stok yetersizliği uyarısı, indirim hesaplama, checkout temizliği.
- **`debt_notifier_test.dart`**: Borç oluşturma doğrulaması, taksit ödeme, kalan bakiye hesabı, durum filtreleme.
- **`sync_service_test.dart`**: Bağlantı yokken hata döndürme, bağlantı kurulduğunda otomatik senkronizasyon.
- **`race_condition_test.dart`**: Çevrimdışı senkronizasyonda aynı anda gelen isteklerin kilit mekanizması ile engellenmesi.

#### Widget Testleri (`test/widget/...`):
- **`shopping_screen_test.dart`**: Ürün listesinin render edilmesi, Ekle butonuna basıldığında sepet rozet sayısının artması, sepet BottomSheet'inin açılıp toplam tutarı göstermesi.
- **`debt_management_screen_test.dart`**: Borç kartlarının ve özet bakiyelerin görünümü, FAB butonuna basıldığında borç ekleme diyalogunun açılması.

#### Entegrasyon & Kullanıcı Yolculuğu Testleri (`integration_test/...` & `test_driver/...`):
- **`shopping_user_journey_test.dart`**: Canlı cihazda uçtan uca alışveriş yapma, sepeti kontrol etme ve ödemeyi tamamlama yolculuğu.
- **`debt_user_journey_test.dart`**: Canlı cihazda uçtan uca borç kaydı açma, 3 takside bölme ve 1. taksiti ödeme yolculuğu.
- **`offline_sync_user_journey_test.dart`**: Canlı cihazda manuel senkronizasyon tetikleme yolculuğu.
- **`test_driver/integration_test.dart`**: Flutter Driver çalıştırma sürücü betiği.

---

## 🛠️ Otomasyon Betikleri

1. **`scripts/test_runner.bat`**: Statik analiz, birim, widget ve entegrasyon testlerini tek komutla çalıştırır.
2. **`scripts/clean_workspace.bat`**: `flutter clean` çalıştırır, `build/`, `coverage/` klasörlerini ve geçici dosyaları temizler, bağımlılıkları t tazeler.

---

## ⚙️ CI/CD Pipeline & Artifact Retention

Workflow dosyası: **`.github/workflows/flutter_test_ci.yml`**

- **Tetiklenme**: `main`, `develop` veya `feat/**` dallarına push yapıldığında.
- **Çıktı Saklama Süresi (`retention-days: 3`)**: GitHub Actions üzerinde oluşturulan `app-release.apk` ve `lcov.info` test kapsama dosyaları 3 gün sonra otomatik silinir; depolama dolmaz.
- **Çalışma Alanı Temizliği (`Post Build Workspace Cleanup`)**: Pipeline sonunda geçici dosyalar ve build artıkları otomatik temizlenir.
