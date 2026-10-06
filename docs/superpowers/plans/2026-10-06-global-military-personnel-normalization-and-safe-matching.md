# Global Askeri Personel Normalizasyonu, Güvenli Akıllı Eşleşme ve Çoklu Aday Yönetimi Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hem metin yapıştırmada (`BulkTextParser`) hem de görsel OCR'da (`RosterOcrNameExtractor`), Jandarma/TSK sınıf eklerini (`J.Per.Asb...`, `J.İkm...`, `J.Mu...`, `J.Asyş...` vb.) tanıyıp ismi saf biçimde ayıklayan merkezi bir normalizasyon motoru kurmak; aynı isim-soyadlı personelleri rütbe/tim bağlamıyla ayırt etmek ve zehirlenmiş akıllı takma adları (poisoned alias) soyadı koruma kalkanıyla engelleyerek sıfır hatalı eşleşme sağlamak.

**Architecture:** 
1. `MilitaryRankNormalizer`: Sınıf eklerini (`Per`, `İkm`, `Mu`, `Bkm`, `Asyş`, `İst`, `Mly`, `Tbp`, `Sağ` vb.) ve askeri rütbeleri standart Jandarma rütbe formatına indirgeyen, metinden rütbeyi sıyırıp saf ad-soyad bırakan tek merkezli ayrıştırıcı.
2. `BulkTextParser` & `RosterOcrNameExtractor`: Kendi içlerindeki dar regex'ler yerine merkezi `MilitaryRankNormalizer`'ı kullanarak sınıf ekli rütbeleri sorunsuz çözer; kelime sayısı veya rakam paraziti nedeniyle satırları çöpe atmaz.
3. `PersonnelFuzzyMatcher`: 
   - **Ters Kapsama:** Gelen ham metin veritabanındaki personelin tüm isim kelimelerini içeriyorsa (%100 token kapsama) doğrudan doğru personeli bulur.
   - **Çoklu Aday Ayrıştırma (Disambiguation):** Aynı isimde birden fazla personel varsa, önce rütbe uyuşmasına, sonra tim/görev uyuşmasına bakar. İpucu yoksa asla rastgele seçmez (`ambiguous`), kullanıcıya onay kartı sunar.
   - **Zehirlenmiş Hafıza Kalkanı (Alias Integrity):** Takma addaki soyadı ile personelin soyadı uyuşmuyorsa alias'ı otomatik işletmez, güvenlik uyarısı verir.

**Tech Stack:** Dart 3.5+, Flutter, Drift, Fuzzy (Levenshtein), Riverpod.

---

## Global Constraints

- Sınıf eki içeren hiçbir rütbe (`J.Per.Asb...`, `J.İkm.Uzm...` vb.) rütbesiz veya tanınmayan personel olarak kalmamalıdır.
- Aynı ad-soyada sahip personellerde sistem ipucu yoksa **asla tahminle veya veritabanı sırasıyla seçim yapmamalıdır** (`candidates.length > 1` belirsiz bırakılmalı).
- Yanlış veya uyuşmayan soyadına sahip akıllı takma adlar (alias) sisteme körü körüne atanmamalı, soyadı tutarlılık süzgecinden geçmelidir.
- Tüm değişiklikler geriye dönük uyumlu olmalı ve mevcut 27+ testin tamamı yeşil kalmalıdır.
- `dart analyze` 0 hata ve 0 uyarı ile tamamlanmalıdır.

---

## Review Focus

1. **Sınıf Ekli Metin Yapıştırma:** `1. J.Per.Asb.Kd.Üçvş. Ahmet Mustafa ÇALIŞKAN` yapıştırıldığında:
   - Rütbe: `J.Asb.Kd.Üçvş.`
   - İsim: `Ahmet Mustafa ÇALIŞKAN`
   - Eşleşme: Veritabanındaki `J.Asb.Kd.Üçvş. Ahmet Mustafa ÇALIŞKAN` ile %100 Confidence (1.0).
2. **Aynı İsim-Soyad - Farklı Rütbe:** Listede `J.Asb.Kd.Çvş. Mehmet KAYA` yazıyorsa, veritabanındaki `J.Uzm.Çvş. Mehmet KAYA` yerine Astsubay olan adayın seçilmesi.
3. **Aynı İsim-Soyad - Farklı Tim:** Listede tim `"1. Tim"` iken iki adet `J.Uzm.Çvş. Mehmet KAYA` arasından 1. Tim'de olanın seçilmesi.
4. **Aynı İsim-Soyad - Eşit Şartlar:** Tim ve rütbe eşit veya belirsizse sistemin rastgele atama yapmayıp `isMatched: false` (veya `ambiguous`) bırakarak kullanıcıya sunması.
5. **Zehirlenmiş Alias Engelleme:** Hafızada `"Ahmet KAYA" ➔ Mehmet YILMAZ` gibi tutarsız bir alias varsa sistemin bunu otomatik eşleştirmemesi.

---

### Task 1: Merkezi Askeri Rütbe ve Sınıf Normalizasyon Motorunu (`MilitaryRankNormalizer`) Oluşturma ve Test Etme

**Files:**
- Create: `lib/core/utils/military_rank_normalizer.dart`
- Create: `test/unit/military_rank_normalizer_test.dart`
- Modify: `lib/core/utils/rank_helper.dart`

- [ ] **Step 1: Zorlu Birim Testlerini Yaz (Red)**:
  `test/unit/military_rank_normalizer_test.dart` içinde:
  - `J.Per.Asb.Kd.Üçvş.` ➔ Standart Rütbe: `J.Asb.Kd.Üçvş.`, İsim: `Ahmet Mustafa ÇALIŞKAN`
  - `J.İkm.Asb.Bçvş.`, `J.Mu.Asb.Kd.Çvş.`, `J.Bkm.Uzm.Çvş.`, `J.Asyş.Tğm.` ayrıştırmaları
  - Başında sıra no, parantez, tire olanlar: `1- J.Per.Asb...`, `|2| J.İkm...`
  - Harf yerine rakam karışan OCR girdileri: `Ahmet Y1LMAZ`, `0sman KAYA`
- [ ] **Step 2: Testleri Çalıştır ve Başarısız Olduğunu Gör**:
  `flutter test test/unit/military_rank_normalizer_test.dart`
- [ ] **Step 3: `MilitaryRankNormalizer` Implementasyonunu Yap**:
  - Jandarma sınıf ekleri regex'i: `(?:Per|İkm|Ikm|Mu|Mhb|Bkm|Asyş|Asys|İst|Ist|Uls|Mly|Tbp|Sağ|Sag|Hrk|Asb|Uzm)`
  - `extractRankAndName(String line)` metodu
  - `cleanOcrDigits(String name)` metodu
  - `RankHelper.normalizeRank` ile entegrasyon
- [ ] **Step 4: Testleri Doğrula (Green)**:
  `flutter test test/unit/military_rank_normalizer_test.dart`
- [ ] **Step 5: Commit**:
  `git commit -am "feat: implement MilitaryRankNormalizer for military branch prefixes and robust rank extraction"`

---

### Task 2: Metin Ayrıştırıcıyı (`BulkTextParser`) Merkezi Normalizer ile Güçlendirme

**Files:**
- Modify: `lib/features/activity/domain/parser/bulk_text_title_parser.dart`
- Modify: `lib/features/activity/domain/parser/bulk_text_personnel_parser.dart`
- Create: `test/unit/bulk_text_parser_extended_test.dart`

- [ ] **Step 1: Sınıf Ekli Metin Testlerini Yaz (Red)**:
  `test/unit/bulk_text_parser_extended_test.dart`:
  - `1. J.Per.Asb.Kd.Üçvş. Ahmet Mustafa ÇALIŞKAN` satırının başarıyla parse edilip `rawRank: 'J.Asb.Kd.Üçvş.'` ve `rawName: 'Ahmet Mustafa ÇALIŞKAN'` olarak çıkmasını test et.
  - Karmaşık formatlı `2. J.İkm.Uzm.Çvş. Kemal DEMİR SABAH` nöbet ekli satır testi.
- [ ] **Step 2: Testleri Çalıştır ve Başarısız Olduğunu Gör**:
  `flutter test test/unit/bulk_text_parser_extended_test.dart`
- [ ] **Step 3: `BulkTextParser` Rütbe Ayrıştırmasını Güncelle**:
  - `_rankPattern` regex'ine sınıf eklerini opsiyonel olarak ekle.
  - `_parsePersonnelLine` içinde `MilitaryRankNormalizer.extractRankAndName` kullanarak rütbe ve ismi güvenle ayır.
- [ ] **Step 4: Testleri Doğrula (Green)**:
  `flutter test test/unit/bulk_text_parser_extended_test.dart`
- [ ] **Step 5: Commit**:
  `git commit -am "feat: enhance BulkTextParser to extract personnel with military branch prefixes"`

---

### Task 3: `PersonnelFuzzyMatcher`: Ters Kapsama, Aynı İsim Ayırt Etme ve Zehirlenmiş Alias Kalkanı

**Files:**
- Modify: `lib/features/activity/domain/parser/personnel_fuzzy_matcher.dart`
- Modify: `lib/features/activity/domain/bulk_import_learning_service.dart`
- Create: `test/unit/personnel_fuzzy_matcher_hard_cases_test.dart`

- [ ] **Step 1: En Zorlu Eşleştirme Testlerini Yaz (Red)**:
  `test/unit/personnel_fuzzy_matcher_hard_cases_test.dart`:
  1. **Ters Kapsama Testi:** `J.Per.Asb.Kd.Üçvş. Ahmet Mustafa ÇALIŞKAN` veritabanındaki `Ahmet Mustafa ÇALIŞKAN` ile 1.0 confidence ile eşleşmeli.
  2. **Aynı İsim - Rütbe Ayrımı:** Veritabanında iki Mehmet KAYA var (biri Astsubay, biri Uzman). `J.Asb.Kd.Çvş. Mehmet KAYA` girildiğinde kesinlikle Astsubay olan seçilmeli.
  3. **Aynı İsim - Tim Ayrımı:** İki Uzman Çavuş Mehmet KAYA var (1. Tim ve 2. Tim). Liste başlığı 1. Tim iken 1. Tim'deki seçilmeli.
  4. **Aynı İsim - Belirsizlik (Tahmin Yok):** İpucu yoksa sistem rastgele birini seçmemeli (`isMatched: false` veya `candidates.length > 1`).
  5. **Zehirlenmiş Alias Kalkanı:** Hafızada soyadı tutmayan bir alias varsa (`ÇALIŞKAN ➔ YILMAZ`) sistem bu alias'ı reddetmeli.
- [ ] **Step 2: Testleri Çalıştır ve Başarısız Olduğunu Gör**:
  `flutter test test/unit/personnel_fuzzy_matcher_hard_cases_test.dart`
- [ ] **Step 3: Eşleştiriciyi ve Güvenlik Kalkanını Kodla**:
  - `_matchPersonnel` içine **Ters Kapsama (Reverse Token Match)** kuralını ekle: `rawTokens.containsAll(dbTokens)`.
  - **Aynı İsim Ayrıştırma:** Adaylar arasında rütbe uyuşmasını kontrol et; ardından tim uyuşmasına bak.
  - **Zehirlenmiş Alias Kontrolü:** `aliasMatch.adSoyad`'ın son kelimesi (soyadı) ile `rawName`'in son kelimesi (soyadı) fonetik/Levenshtein olarak tamamen alakasız ise alias'ı yoksay.
- [ ] **Step 4: Testleri Doğrula (Green)**:
  `flutter test test/unit/personnel_fuzzy_matcher_hard_cases_test.dart`
- [ ] **Step 5: Commit**:
  `git commit -am "feat: implement reverse token matching, rank/team disambiguation and alias safety in PersonnelFuzzyMatcher"`

---

### Task 4: OCR Ayıklayıcıyı (`RosterOcrNameExtractor`) Güçlendirme & Çift Satır Desteği

**Files:**
- Modify: `lib/features/activity/domain/ocr/roster_ocr_name_extractor.dart`
- Modify: `lib/features/activity/services/roster_image_import_service.dart`
- Create: `test/features/activity/roster_ocr_hard_cases_test.dart`

- [ ] **Step 1: Zorlu OCR Testlerini Yaz (Red)**:
  `test/features/activity/roster_ocr_hard_cases_test.dart`:
  - `J.Per.Asb.Kd.Üçvş. Ahmet Mustafa ÇALIŞKAN` OCR çıktısından ismi eksiksiz çıkarma testi.
  - İki satıra bölünen isim: `1 J.Uzm.Çvş. Ali İhsan` / `KORKMAZ` birleştirme testi.
  - Rakam kayması içeren satır: `1. 0sman KAYA SABAH` satırından ismi kurtarma testi.
- [ ] **Step 2: Testleri Çalıştır ve Başarısız Olduğunu Gör**:
  `flutter test test/features/activity/roster_ocr_hard_cases_test.dart`
- [ ] **Step 3: OCR Motorunu Güncelle**:
  - `_rankPattern`'i `MilitaryRankNormalizer` ile eşitle.
  - Rakam içeren kelimeleri doğrudan çöpe atmak yerine OCR harf düzeltmesine tabi tut (`0->O`, `1->I`).
  - İki satır ardışık isim birleştirici (Stitcher) ekle.
- [ ] **Step 4: Testleri Doğrula (Green)**:
  `flutter test test/features/activity/roster_ocr_hard_cases_test.dart`
- [ ] **Step 5: Commit**:
  `git commit -am "feat: upgrade RosterOcrNameExtractor with multi-line stitching and military branch rank parsing"`

---

### Task 5: Tüm Test Süitinin Doğrulanması, Regresyon ve CI Kontrolü

**Files:**
- Run: Tüm testler (`test/unit/...`, `test/features/...`)
- Run: `dart analyze`

- [ ] **Step 1: Tüm testleri çalıştır ve 0 hata doğrula**:
  `flutter test`
- [ ] **Step 2: Statik analizi çalıştır ve 0 uyarı doğrula**:
  `dart analyze`
- [ ] **Step 3: Auto Git Flow**:
  - Yeni branch (`feat/global-personnel-normalizer-and-safe-matcher`) veya mevcut dalı hazırla.
  - Commit ve push yap.
- [ ] **Step 4: Kullanıcıya sun**: Yapılan geliştirmeleri ve sağlanan tam güvenceyi açıkla.
