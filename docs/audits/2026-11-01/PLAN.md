# Kod tabanı inceleme planı

Kullanıcı talebi: uygulama kodunu ve mevcut iş kurallarını değiştirmeden rapor,
testler, ayrı Android emülatöründe doğrulama ve yeni GitHub dalına push.

Base: `9517d9464b702a22407be7c515e38e418bdb7032`.
Dal: `audit/codebase-2026-11-01`. Çalışma: `F:/personelapp2`.

- [x] Repo, kurallar, CI, dependency, test ve mimari envanterini incele.
- [x] Bağımsız salt okunur kod kalitesi ve veri bütünlüğü incelemelerini başlat.
- [x] Tam mevcut testleri ve analizi çalıştır; başlangıç sorunlarını ayır.
- [x] Sentetik verili Android testine açık/koyu personel arama, boş sonuç,
  sıralamadan vazgeçme ve DB değişmezliği kontrollerini ekle.
- [x] Mevcut arşiv/çıktı ve aylık analitik senaryolarını aynı testte çalıştır.
- [x] Ekran görüntülerini kaydet ve görsel olarak incele.
- [x] Bulguları önem, kanıt, test ve güvenli düzeltme önerisiyle raporla.
- [x] Diff, kaynak değişmezliği, test hash'leri ve staged dosyaları doğrula.
- [x] Yalnız rapor/test/görev kayıtlarını Conventional Commit ile push et.

Kapsam dışı: production düzeltmesi, refactor, dependency yükseltmesi, migration,
release/deploy, merge, gerçek kullanıcı verisiyle test ve fiziksel cihaz testi.
Risk: Tier 2 test/rapor işi; production davranışı ve veri sözleşmesi değişmiyor.
Test AVD kimliği her yükleme öncesi doğrulanır: `nizam-nobet-test`.
Başlangıçtaki `.playwright-cli/`, `.serena/`, `output/` korunur.
Yeni özellik/hata düzeltmesi yapılmadığından red/green production patch döngüsü N/A.
