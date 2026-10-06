# İmzalı Liste Saat Aralığı & Çıktı Hazırlama Kart Eksilme Akışı Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resmi isim listesi başlıklarını kurallı Türkçe ve isteğe bağlı saat aralığıyla üretmek; dışa aktarma penceresinde hızlı saat girdisi sunmak ve "Çıktı Hazırla" ekranında seçilen kartların alttaki listeden eksilmesini sağlayarak temiz bir seçim ergonomisi oluşturmak.

**Architecture:** 
1. `OfficialRosterTitle.format`: `timeRange` parametresi eklenerek `[Birlik] [Tarih] TARİHİ ([Saat] SAATLERİ ARASI) [Faaliyet] PERSONEL İSİM LİSTESİ` formatına güncellenir; exporter servisleri bu parametreyi zincirler.
2. `ArchiveExportSheet`: Kullanıcıdan isteğe bağlı saat aralığı alan bir metin girişi ve hızlı çipleri (`06.00-08.00`, `20.00-08.00` vb.) barındırır; `ArchiveExportResult(type, timeRange)` döndürür. Saat yazılmadığında mevcut akış hiçbir engelle karşılaşmadan doğrudan çalışır.
3. `RosterOutputScreen`: Alttaki "Aynı Günün Kartları" ve "Önceki Günün Kartları" listelerinde yalnızca henüz seçilmemiş (`!ids.contains(card.id)`) kartlar gösterilir; kart seçildiğinde üstteki "Çıktıya Eklenecekler" listesine geçer, üstten çıkarıldığında alttaki havuza geri döner.

**Tech Stack:** Flutter (Material 3), Riverpod, Dart 3.5+, Drift.

---

## Global Constraints

- Askeri başlık formatı harfiyen kurallı Türkçe olmalı; devrik veya ek düşmesi içeren yapı kullanılmamalıdır.
- Saat aralığı tamamen isteğe bağlıdır; boş bırakıldığında kullanıcı tek tıkla doğrudan Excel/PDF/Yazdır çıktısı alabilmelidir.
- Kart çıkarma/ekleme işlemleri salt arayüz durumunu (`_currentIds`, `_previousIds`) yönetir, veri tabanındaki orijinal faaliyet ve personelleri asla silmez veya değiştirmez.
- Tüm `dart analyze` ve `flutter test` adımları 0 hata ile geçmelidir.

---

## Review Focus

1. **Saat Aralığı Boş Bırakıldığında**: Başlıkta parantez veya fazladan boşluk kalmamalı (`... TARİHİ FAALİYET PERSONEL İSİM LİSTESİ`).
2. **Saat Aralığı Girildiğinde**: Parantez ve saatler tam standartta yer almalı (`... TARİHİ (06.00-08.00 SAATLERİ ARASI) HEYBET TEPE PUSU FAALİYETİ PERSONEL İSİM LİSTESİ`).
3. **Kart Seçildiğinde Alttan Eksilme**: Alttaki listede seçilen kart anında gizlenmeli, üstteki sıralama kartlarında görünmeli.
4. **Kart Çıkarıldığında Geri Dönüş**: Üstteki kart listesinden silinen kart anında alttaki havuza geri dönmeli.
5. **Tüm Kartlar Seçildiğinde Boş Durum**: Tüm kartlar eklendiğinde altta "Tüm kartlar çıktıya eklendi." bilgilendirme mesajı gösterilmeli.

---

### Task 1: `OfficialRosterTitle` Başlık Şablonunu ve Birim Testlerini Güncelleme

**Files:**
- Modify: `lib/core/utils/official_roster_title.dart`
- Modify: `test/unit/official_roster_title_test.dart`

- [x] **Step 1: Testleri hazırla (Red)**: `test/unit/official_roster_title_test.dart` dosyasına saatli ve saatsiz yeni kurallı Türkçe başlık formatını doğrulayan testleri ekle.
- [x] **Step 2: Testleri çalıştır ve başarısız olduğunu gör**: `flutter test test/unit/official_roster_title_test.dart`
- [x] **Step 3: `OfficialRosterTitle.format` implementasyonunu yap**: `timeRange` opsiyonel parametresini ekle; `KOVANCILAR JÖH TB.K.LIĞI 01.10.2026 TARİHİ (06.00-08.00 SAATLERİ ARASI) [Faaliyet] PERSONEL İSİM LİSTESİ` formatını üret.
- [x] **Step 4: Testleri doğrula (Green)**: `flutter test test/unit/official_roster_title_test.dart`
- [x] **Step 5: Commit**: `git commit -am "feat: update official roster title with grammatical Turkish and optional time range"`

---

### Task 2: Dışa Aktarma Servislerine (`Exporter`) Saat Aralığı Parametresi Desteği

**Files:**
- Modify: `lib/features/activity/services/military_roster_exporter.dart`
- Modify: `lib/features/activity/services/pdf_roster_exporter.dart`
- Modify: `lib/features/activity/services/exporter/excel_xlsx_military_generator.dart`
- Modify: `lib/features/activity/services/pdf_roster_styles.dart`
- Modify: `test/unit/heybet_print_layout_test.dart`

- [x] **Step 1: Testi güncelle (Red)**: `heybet_print_layout_test.dart` içerisinde saat aralığı verildiğinde Excel ve PDF çıktılarında başlığın saati içerdiğini doğrulayan testi ekle.
- [x] **Step 2: Exporter parametrelerini genişlet**: `MilitaryRosterExporter.generateMilitaryExcelBytes`, `shareExcelRoster`, `shareTextRoster`, `PdfRosterExporter` ve ilgili generator metodlarına `String? timeRange` parametresini ekle ve `OfficialRosterTitle.format`'a ilet.
- [x] **Step 3: Testleri çalıştır (Green)**: `flutter test test/unit/heybet_print_layout_test.dart`
- [x] **Step 4: Commit**: `git commit -am "feat: thread time range parameter through military roster exporters"`

---

### Task 3: `ArchiveExportSheet` Arayüzüne İsteğe Bağlı Saat Girişi ve Hızlı Seçim Çipleri Ekleme

**Files:**
- Modify: `lib/features/activity/presentation/widgets/archive_export_sheet.dart`
- Modify: `lib/features/activity/presentation/roster_output_preview_screen.dart`
- Modify: `lib/features/activity/presentation/widgets/activity_detail_assignments.dart`

- [x] **Step 1: `ArchiveExportResult` modelini tanımla**:
  ```dart
  class ArchiveExportResult {
    final ArchiveExportType type;
    final String? timeRange;
    const ArchiveExportResult(this.type, {this.timeRange});
  }
  ```
- [x] **Step 2: `ArchiveExportSheet` içine saat giriş alanını yerleştir**:
  - `TextEditingController` ile saat kutusu: `Örn: 06.00-08.00`
  - Hızlı çip butonları: `[06.00-08.00]`, `[08.00-10.00]`, `[20.00-08.00]`, `[Temizle]`
  - Kullanıcı doğrudan Excel/PDF/Yazdır/Metin seçtiğinde `ArchiveExportResult(type, timeRange: controller.text.trim())` döndür.
- [x] **Step 3: Çağrıcıları (`roster_output_preview_screen.dart` ve `activity_detail_assignments.dart`) güncelle**:
  - Dönen `ArchiveExportResult`'tan `timeRange` bilgisini alıp `exporter` servislerine aktar.
- [x] **Step 4: Manuel/widget testi ile doğrula**: Saat yazılmadığında eski doğrudan tıklama davranışının korunduğunu kontrol et.
- [x] **Step 5: Commit**: `git commit -am "feat: add optional time range input and quick chips to ArchiveExportSheet"`

---

### Task 4: `RosterOutputScreen`'de Seçilen Kartların Havuzdan Eksilmesi ve Geri Dönüşü

**Files:**
- Modify: `lib/features/activity/presentation/roster_output_screen.dart`
- Modify: `test/features/activity/roster_output_screen_test.dart`

- [x] **Step 1: Testi güncelle (Red)**:
  - `roster_output_screen_test.dart`'ta kart eklendiğinde alttaki listeden kaybolduğunu, üstteki silme butonuyla kaldırıldığında tekrar alttaki listede belirdiğini test eden senaryoyu yaz.
- [x] **Step 2: `_available` metodunu güncelle**:
  - `final unselectedCards = cards.where((c) => !ids.contains(c.id)).toList();`
  - Alttaki kartlar artık Checkbox yerine doğrudan şık bir `+ Ekle` veya tıklanabilir kart olarak listelenir. Tıklanınca `ids.add(card.id)` çalışır.
  - Eğer `unselectedCards.isEmpty` ise: `Text('Bu güne ait tüm kartlar çıktıya eklendi.')` mesajı gösterilir.
- [x] **Step 3: Testleri çalıştır (Green)**: `flutter test test/features/activity/roster_output_screen_test.dart`
- [x] **Step 4: Commit**: `git commit -am "feat: deplete selected cards from available lists and restore on removal in RosterOutputScreen"`

---

### Task 5: Uçtan Uca Doğrulama, Regresyon ve CI Kontrolü

**Files:**
- Test: `test/unit/official_roster_title_test.dart`
- Test: `test/features/activity/roster_output_screen_test.dart`
- Test: `test/features/activity/separate_heybet_excel_test.dart`
- Test: `test/unit/heybet_print_layout_test.dart`

- [x] **Step 1: Tüm ilgili testleri çalıştır**:
  `flutter test test/unit/official_roster_title_test.dart test/features/activity/roster_output_screen_test.dart test/features/activity/separate_heybet_excel_test.dart test/unit/heybet_print_layout_test.dart`
- [x] **Step 2: Statik analiz çalıştır**:
  `dart analyze`
- [x] **Step 3: Dalı uzak depoya push et**:
  `git push origin feat/roster-output-builder`
- [x] **Step 4: Kullanıcıya sun**: Değişiklikleri ve kullanıcı deneyimindeki ergonomiyi açıkla.
