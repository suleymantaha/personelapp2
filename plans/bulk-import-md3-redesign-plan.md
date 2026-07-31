# BulkImportDialog — MD3 + Apple HIG Yeniden Tasarım Planı

## Hedef Mimari

```
┌─────────────────────────────────────────────────────┐
│  Toplu Aktarım                                 [✕]  │
│  Whatsapp / Telegram nöbet listelerini yapıştırın    │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ○ Yapıştır  ●  Önizleme  ○ Kaydet    (Stepper)     │
│                                                      │
│  ┌───────┐  ┌───────┐  ┌───────┐                    │
│  │   8   │  │  56   │  │   2   │   (Stat Kartları)  │
│  │ Kart  │  │Personel│  │  Gün  │                    │
│  └───────┘  └───────┘  └───────┘                    │
│                                                      │
│  ❌ Kaydedilemiyor — 1 kritik hata ▼  (Hata Özeti)  │
│  ⚠ 4 uyarı                                           │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │🟥 10/B    HEYBET                        ⋮   │    │
│  │    📅 31 Temmuz 2026  👥 5 Personel         │    │
│  │    ❌ Aynı personel başka görevde            │    │
│  └──────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────┐    │
│  │🟢 6/B     DEVRİYE                       ⋮   │    │
│  │    📅 31 Temmuz 2026  👥 3 Personel         │    │
│  │    ✅ Hazır                                  │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  ─────────────────────────────────────────────────   │
│  ❌ Önce kritik hataları çözün                       │
│  [ Hataları Göster ]                  (Akıllı Buton) │
│  ─────────────────────────────────────────────────   │
└─────────────────────────────────────────────────────┘
```

---

## Faz 1: Stepper + Layout Restructure

### Mevcut Durum
- Mobile: `TabBar` + `TabBarView` (2 sekme)
- Desktop: `Row` ile yan yana Input ve Preview
- `_tabController` state'i yönetiyor

### Hedef
- 3 adımlı yatay stepper: `Yapıştır → Önizleme → Kaydet`
- Adım 3 ("Kaydet") = onay özeti + save butonu, sadece tüm sorunlar çözüldüğünde aktif
- Mobile: Stepper her zaman görünür, içerik altında değişir
- Desktop: Input ve Preview yan yana kalır, stepper progress göstergesi olarak üstte

### Değişiklikler
- `_tabController` → `int _currentStep = 0` (0-2)
- `_currentStep` değiştikçe içerik değişir
- `_tabController` ve `SingleTickerProviderStateMixin` kaldırılır
- Custom stepper widget (`_BulkImportStepper`) — Flutter'ın `Stepper` widget'ı değil, daha hafif özel bir implementasyon

```dart
// Yeni state değişkeni
int _currentStep = 0; // 0: paste, 1: preview, 2: confirm

// Desktop'ta adım 0'da yan yana gösterme (input + boş preview), 
// adım 1'de yan yana (input + dolu preview)
// Mobilde sadece aktif adımın içeriği gösterilir
```

### Stepper Widget Tasarımı
```
  ○─────────●─────────○
Yapıştır  Önizleme  Kaydet
```
- Aktif adım: dolu daire + accent renk
- Tamamlanan adım: checkmark + accent renk
- Gelecek adım: boş daire + gri
- Bağlantı çizgileri: tamamlanan kısım accent, kalan kısım gri

---

## Faz 2: İstatistik Kartları

### Mevcut Durum
`_ImportSummary` → iki satır `_SummaryChip` (yatay scroll ile)

### Hedef
3 adet eşit genişlikte stat kartı: **Kart**, **Personel**, **Gün**

### Tasarım
```dart
Row(
  children: [
    _StatCard(number: cardCount, label: 'Kart', icon: Icons.assignment),
    _StatCard(number: personnelCount, label: 'Personel', icon: Icons.groups),
    _StatCard(number: uniqueDayCount, label: 'Gün', icon: Icons.calendar_month),
  ],
)
```

### _StatCard Widget'ı
```dart
// ┌──────────┐
// │    8     │  ← fontSize: 28, bold
// │ 📄 Kart  │  ← fontSize: 12, muted
// └──────────┘
// Container: borderRadius: 12, light background, subtle border
```

Not: `_ImportSummary` sınıfı tamamen kaldırılır, `_SummaryChip` de öyle.

---

## Faz 3: Kompakt Hata Özeti

### Mevcut Durum
- `_buildParseIssues()` → `ExpansionTile` içinde `Card` — çok yer kaplıyor (başlık + subtitle + liste)
- Wizard bar ayrı bir amber kutu

### Hedef
Tek satırda kompakt hata özeti. Tıklanınca wizard başlar + detaylar açılır.

### İki Durum

**Kritik hata varsa:**
```
┌────────────────────────────────────────────┐
│ ❌ Kaydedilemiyor — 1 kritik hata    ▼    │
└────────────────────────────────────────────┘
```

**Sadece uyarı varsa:**
```
┌────────────────────────────────────────────┐
│ ⚠ 4 uyarı — Kayıt yapılabilir       ▼    │
└────────────────────────────────────────────┘
```

**Hiç sorun yoksa:**
```
┌────────────────────────────────────────────┐
│ ✅ Tüm kontroller tamam — Kayda hazır     │
└────────────────────────────────────────────┘
```

### Davranış
- Tıklandığında: wizard başlatılır (ilk soruna odaklanır)
- Açılır ok (▼/▲): parse issue detayları gösterilir/gizlenir
- Kırmızı: `Colors.red.shade50` arka plan + `#D32F2F` kenar
- Turuncu: `Colors.amber.shade50` arka plan + `#F59E0B` kenar
- Yeşil: `Colors.green.shade50` arka plan + `#16A34A` kenar

### Yeni Widget: `_CompactErrorSummary`
`_buildParseIssues()` ve `_ProblemWizardBar`'ın yerini alır. Tek bir widget hem hata özetini hem wizard navigasyonunu hem de parse issue detaylarını içerir.

---

## Faz 4: Kart Yeniden Tasarımı

### Mevcut Durum
- `_buildPreviewCard` → `Card` widget, içinde `Column`: başlık, metadata, personel listesi
- `_Personnel{