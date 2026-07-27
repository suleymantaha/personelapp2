# Flutter Project Context — personelapp2

> **Bu dosya her agent tarafından kodlamaya başlamadan ÖNCE okunmalıdır.**
> Multi-agent army ordusu bu dosyayı referans olarak kullanır.

---

## 📋 Proje Özeti

**Uygulama Adı:** Jandarma Görev Takip Uygulaması  
**Paket:** `personelapp2`  
**Dart SDK:** `^3.12.2`  
**Amaç:** Jandarma birliklerinde personel ve tim yönetimi, günlük faaliyet çizelgesi, aylık matris, PDF rapor

---

## 🛠️ Tech Stack

| Katman | Teknoloji | Versiyon |
|--------|-----------|---------|
| UI Framework | Flutter (Material 3) | latest |
| State Management | Riverpod (`flutter_riverpod`) | ^2.6.1 |
| Database | Drift (SQLite) | ^2.34.2 |
| Navigation | go_router | ^17.3.0 |
| Localization | intl | ^0.20.3 |
| PDF | pdf + printing | ^3.13.0 / ^5.15.0 |
| Share | share_plus | ^13.2.1 |
| Storage | shared_preferences | ^2.5.5 |
| Crypto | crypto | ^3.0.6 |
| Icons | material_design_icons_flutter | ^7.0.7296 |

**Dev Dependencies:** `build_runner`, `drift_dev`, `flutter_lints`, `very_good_analysis`

---

## 📁 Proje Yapısı

```
lib/
├── main.dart                              ← App entry point, ProviderScope, MaterialApp.router
├── core/
│   ├── database/
│   │   ├── tables.dart                    ← Drift table definitions (7 tablo)
│   │   ├── database.dart                  ← AppDatabase, schemaVersion=2, ensureSeeded()
│   │   └── database.g.dart                ← Generated (dart run build_runner build)
│   ├── navigation/
│   │   └── app_router.dart               ← go_router routes
│   ├── providers/
│   │   └── providers.dart                ← All Riverpod providers
│   ├── services/
│   │   └── session_storage.dart          ← SharedPreferences session persistence
│   ├── theme/
│   │   ├── app_theme.dart                ← AppColors, AppTheme, ThemeContext extension
│   │   └── responsive_layout.dart        ← ResponsiveCenter, context extensions
│   └── utils/                            ← Utility functions
└── features/
    ├── auth/
    │   └── presentation/
    │       └── login_screen.dart          ← Login ekranı
    ├── dashboard/
    │   └── presentation/
    │       └── dashboard_screen.dart      ← Ana menü (grid kartları)
    ├── personnel/
    │   ├── data/
    │   │   └── personnel_repository.dart  ← PersonnelRepository (Drift DAO)
    │   └── presentation/
    │       └── personnel_management_screen.dart
    ├── activity/
    │   ├── data/
    │   │   └── activity_repository.dart   ← ActivityRepository (Drift DAO)
    │   └── presentation/
    │       ├── activity_form_screen.dart
    │       ├── activity_archive_screen.dart
    │       └── pending_approvals_screen.dart
    └── matrix/
        ├── data/
        │   └── matrix_repository.dart     ← MatrixRepository (Drift DAO)
        └── presentation/
            └── monthly_matrix_screen.dart

test/
└── unit/
    └── matrix_repository_test.dart        ← Örnek unit test
```

---

## 🗄️ Veritabanı Şeması (Drift Tables)

### KullaniciTable (Kullanıcılar)
```dart
id: int (PK, autoIncrement)
kullaniciAdi: text (unique)
sifre: text (default '')
rol: text  // 'yönetici' veya 'tim_komutani'
timId: int? (FK → TimTable.id, onDelete: setNull)
```

### TimTable (Timler)
```dart
id: int (PK, autoIncrement)
timAdi: text
timKomutaniId: int? (FK → KullaniciTable.id, onDelete: setNull)
olusturmaTarihi: text (ISO8601)
```

**Varsayılan Timler (seed):**
`K.H`, `1'inci Bl. K.H`, `1-B Timi`, `2-B Timi`, `3-B Timi`, `4-B Timi`,
`2'nci Bl. K.H`, `5-B Timi`, `6-B Timi`, `7-B Timi`, `8-B Timi`,
`3'üncü Bl. K.H`, `9-B Timi`, `10-B Timi`, `11-B Timi`, `12-B Timi`

### PersonelTable (Personeller)
```dart
id: int (PK, autoIncrement)
adSoyad: text
rutbe: text
birlik: text
timId: int? (FK → TimTable.id, onDelete: setNull)
kayitTarihi: text (ISO8601)
```

### GunlukFaaliyetTable (Günlük Faaliyetler)
```dart
id: int (PK, autoIncrement)
faaliyetAdi: text
tarih: text  // YYYY-AA-DD
olusturanKullanici: text
olusturmaTarihi: text (ISO8601)
```

### FaaliyetPersonelAtamaTable (Faaliyet-Personel Atamaları)
```dart
id: int (PK, autoIncrement)
faaliyetId: int (FK → GunlukFaaliyetTable.id, onDelete: cascade)
personelId: int (FK → PersonelTable.id, onDelete: cascade)
gorevVeyaIzin: text  // 'GÖREVLİ' | 'NÖBETÇİ' | 'İZİNLİ' | 'İSTİRAHATLİ' | 'RAPORLU' | 'SEVK'
durum: text           // 'onaylandi' | 'beklemede' | 'reddedildi'
aciklama: text?
```

### RaporKayitTable (Rapor Kayıtları)
```dart
id: int (PK, autoIncrement)
personelId: int (FK → PersonelTable.id, onDelete: cascade)
raporBaslangic: text  // YYYY-AA-DD
raporBitis: text      // YYYY-AA-DD
aciklama: text?
```

### TimUyelikGecmisiTable (Tim Üyelik Geçmişi)
```dart
id: int (PK, autoIncrement)
personelId: int
timId: int? (FK → TimTable.id)
tarih: text  // YYYY-AA-DD
islem: text  // 'eklendi' | 'çıkarıldı'
```

---

## 🔄 Navigation (go_router Routes)

| Route | Screen | Açıklama |
|-------|--------|----------|
| `/login` | `LoginScreen` | İlk açılış, kimlik doğrulama |
| `/dashboard` | `DashboardScreen` | Ana menü |
| `/activity-form` | `ActivityFormScreen` | Günlük faaliyet girişi |
| `/pending-approvals` | `PendingApprovalsScreen` | Bekleyen onaylar (Admin) |
| `/personnel-management` | `PersonnelManagementScreen` | Personel ve tim yönetimi |
| `/monthly-matrix` | `MonthlyMatrixScreen` | Aylık matris görünümü |
| `/activity-archive` | `ActivityArchiveScreen` | Faaliyet arşivi |

**Navigation Pattern:** `context.push('/route')` for stack push, `context.go('/route')` for replace.

---

## 🎣 Riverpod Providers

Tüm providers `lib/core/providers/providers.dart` dosyasında tanımlı:

```dart
// Singleton Database
final databaseProvider = Provider<AppDatabase>((ref) { ... });

// Repositories
final personnelRepositoryProvider = Provider<PersonnelRepository>((ref) { ... });
final activityRepositoryProvider = Provider<ActivityRepository>((ref) { ... });
final matrixRepositoryProvider = Provider<MatrixRepository>((ref) { ... });

// Auth
final userSessionProvider = StateProvider<UserSessionState?>((ref) => null);
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Personnel Streams
final allPersonnelProvider = StreamProvider<List<PersonelTableData>>(...);
final allSquadsProvider = StreamProvider<List<TimTableData>>(...);
final allCommandersProvider = StreamProvider<List<KullaniciTableData>>(...);

// Activity
final pendingAssignmentsProvider = StreamProvider<List<FaaliyetPersonelAtamaTableData>>(...);
final filteredActivitiesProvider = StreamProvider<List<GunlukFaaliyetTableData>>(...);

// Matrix
final monthlyMatrixProvider = StreamProvider.family<Map<int, Map<int, String>>, String>(...);
```

**UserSessionState:**
```dart
class UserSessionState {
  final String username;
  final String role;  // 'yönetici' | 'tim_komutani'
  final int? timId;
  bool get isAdmin => role == 'yönetici';
}
```

---

## 🎨 Theme System

### AppTheme Kullanımı
```dart
// Tema
AppTheme.militaryTheme     // Light tema
AppTheme.darkMilitaryTheme // Dark tema
```

### ThemeContext Extensions (BuildContext üzerinde)
```dart
// Mode
context.isDarkMode                    // bool

// Renkler
context.textPrimary                   // Color
context.textSecondary                 // Color
context.textMuted                     // Color
context.accentOrOlive                 // Olive green (light) / Khaki (dark)
context.rejectedColor                 // Kırmızı tonu
context.rejectedBgColor               // Arka plan
context.rejectedBorderColor           // Kenar
context.approvedColor                 // Yeşil
context.pendingColor                  // Sarı
context.blueGreyColor                 // Mavi gri
context.tealColor                     // Teal
context.brownColor                    // Kahverengi
context.headerBg                      // AppBar arka plan
context.shadowColor                   // Gölge rengi
context.colorScheme                   // Material ColorScheme

// Matris durum renkleri
context.getStatusBgColor(String status)   // 'GÖREVLİ' | 'İZİNLİ' | 'RAPOR' | 'beklemede'
context.getStatusTextColor(String status)
```

### AppColors (Static)
```dart
AppColors.militaryOlive     // #4A5D36 — Primary
AppColors.darkOlive         // #2E3B21 — Dark Accent
AppColors.lightOlive        // #E8EFE0 — Container BG
AppColors.approvedGreen     // #2E7D32
AppColors.pendingYellow     // #F57F17
AppColors.rejectedRed       // #C62828
```

---

## 📐 Responsive Layout

```dart
// Wrapper widget (wrap screen content with this)
ResponsiveCenter(
  maxWidth: 900,  // Optional, default varies
  child: content,
)

// Grid column count
context.gridCrossAxisCount()  // Returns 2 (mobile), 3 (tablet), 4 (desktop)

// Responsive value
context.responsiveValue(
  mobile: 1.1,
  tablet: 1.2,
  desktop: 1.3,
)
```

---

## 🧱 Code Conventions

### Widget Structure
```dart
// Prefer ConsumerWidget for widgets that watch providers
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(someProvider);
    return Scaffold(...);
  }
}

// Use ConsumerStatefulWidget only when local state needed
```

### Drift DAO Pattern
```dart
part of '../database/database.dart';  // or as mixin

@DriftAccessor(tables: [MyTable])
class MyDao extends DatabaseAccessor<AppDatabase> with _$MyDaoMixin {
  MyDao(super.db);

  // Streams for reactive UI
  Stream<List<MyTableData>> watchAll() => select(myTable).watch();

  // Futures for one-shot reads
  Future<List<MyTableData>> getAll() => select(myTable).get();

  // Mutations
  Future<void> insertItem(MyTableCompanion item) => into(myTable).insert(item);
}
```

### Riverpod Pattern
```dart
// Streams from DAO
final myDataProvider = StreamProvider<List<MyTableData>>((ref) {
  return ref.watch(myRepositoryProvider).watchAll();
});

// In widget: handle all AsyncValue states
ref.watch(myDataProvider).when(
  data: (list) => MyWidget(list),
  loading: () => const CircularProgressIndicator(),
  error: (err, st) => Text('Hata: $err'),
);
```

### Navigation Pattern
```dart
// Push (stack ekle)
context.push('/route');
context.push('/route', extra: someData);

// Replace (stack yenile)
context.go('/route');

// Pop
Navigator.of(context).pop();
// or context.pop();
```

### Error Handling
```dart
// Always use mounted check after async gaps
if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}

// Use debugPrint for logging (never print())
debugPrint('Debug info: $value');
```

### Async Patterns
```dart
// Use unawaited() for fire-and-forget async calls
import 'dart:async';
unawaited(showModalBottomSheet(...));

// Always await DB operations in event handlers
onTap: () async {
  await repo.insertItem(item);
}
```

---

## 🧪 Test Conventions

**Test Dosyaları:** `test/unit/` (unit), `test/widget/` (widget)

### Unit Test (Drift Memory DB)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';

void main() {
  late AppDatabase db;
  late MatrixRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MatrixRepository(db);
  });

  tearDown(() async => db.close());

  test('should return empty matrix for new month', () async {
    final result = await repo.getMonthlyMatrix(yearMonth: '2026-07');
    expect(result, isEmpty);
  });
}
```

### Widget Test
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('DashboardScreen shows menu cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userSessionProvider.overrideWith((ref) => UserSessionState(
            username: 'test',
            role: 'yönetici',
          )),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Faaliyet Çizelgesi'), findsOneWidget);
  });
}
```

---

## ⚠️ Critical Rules (Her Agent Uymalı)

1. **ASLA `print()` kullanma** → `debugPrint()` kullan
2. **ASLA hardcoded renk** → `context.accentOrOlive`, `AppColors.*` kullan
3. **ASLA hardcoded boyut** (responsive olmayan) → `context.responsiveValue()` kullan
4. **`context.mounted` kontrolü** her async gap sonrası
5. **`const` constructor** her yerde kullan
6. **`flutter analyze` 0 hata** ile teslim et
7. **Drift şema değişikliği** → `schemaVersion` artır + migration yaz + `build_runner` çalıştır
8. **Yeni route ekle** → `app_router.dart`'a ekle
9. **Yeni provider ekle** → `providers.dart`'a ekle (tek merkezi yer)
10. **Türkçe UI label** → `const Text('Türkçe Metin')` şeklinde
11. **`unawaited()`** → fire-and-forget async çağrılar için (`import 'dart:async'`)
12. **Platform hedefleri:** Windows + Android + iOS + Web — platform-specific kod guard ile

---

## 🔧 Yararlı Komutlar

```powershell
# Flutter
flutter pub get                          # Bağımlılıkları yükle
flutter analyze                          # Statik analiz (0 hata gerekli)
dart format .                            # Kod formatla
dart format --set-exit-if-changed .      # Format kontrol (CI için)
flutter test                             # Tüm testler
flutter test --coverage                  # Coverage raporu
dart fix --apply                         # Otomatik düzeltmeler
dart fix --dry-run                       # Düzeltme önizleme

# Drift Codegen
dart run build_runner build              # Tek seferlik
dart run build_runner watch              # Geliştirme sırasında

# Uygulama başlatma
flutter run -d windows                   # Windows desktop
flutter run -d android                   # Android
flutter run                              # Varsayılan bağlı cihaz

# Dart MCP Server (agent araçları)
dart_mcp_server/analyze_files           # flutter analyze alternatifi
dart_mcp_server/hot_reload              # Kod değişikliği sonrası
dart_mcp_server/get_runtime_errors      # Aktif runtime hatalar
dart_mcp_server/lsp                     # Code navigation
```

---

## 📦 Yeni Özellik Ekleme Adımları

1. `lib/features/<özellik_adı>/` klasörü oluştur
2. Katmanları oluştur: `data/`, `presentation/`
3. Gerekirse `lib/core/database/tables.dart`'a tablo ekle → `build_runner` çalıştır
4. Repository/DAO ekle → `lib/core/providers/providers.dart`'a provider ekle
5. Screen widget oluştur → `lib/core/navigation/app_router.dart`'a route ekle
6. `DashboardScreen`'e gerekirse `_MenuCard` ekle
7. Test yaz: `test/unit/<özellik>_test.dart` + `test/widget/<özellik>_test.dart`
8. `flutter analyze` + `flutter test` çalıştır → 0 hata ile teslim et
