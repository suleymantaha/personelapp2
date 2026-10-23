---
name: UMAF v3.0 Orkestrasyon
description: Tier kararı, alt görev zarfı, kanıt kapısı, devre kesici veya kalite, orkestrasyon ve güvenlik politikası gerektiğinde yükle.
metadata:
  opencode/autoinvoke: true
---

Bu dosya kitin operasyonel prosedürüdür. Buradaki karar kuralları tek başına yeterlidir; proje içindeki `.agents/**` belgeleri isteğe bağlı derin referanstır.

## 1. Tier seçimi

Beş soruyu sırayla sor, cevabı ve gerekçeyi yaz.

1. Kullanıcı verisi, sır veya dosya silinebilir, açığa çıkabilir, yanlış kişiye verilebilir mi?
2. Para, hak, kota veya hesap yetkisi değişiyor mu?
3. API veya şema tüketicileri, dosya veya belge ayrıştırıcıları, migration, asenkron iş durumu etkileniyor mu?
4. Yanlışlık üretimde geri alınamaz sonuç doğurur mu?
5. Kök neden ilk bakışta belirsiz mi veya birden fazla alt sistem etkileniyor mu?

Kural:
- 1 veya 2 evet ise Tier 3.
- 3 veya 5 evet ise en az Tier 2.
- Hepsi hayır ise Tier 1.
- Cevap bilinmiyorsa riskli tarafı seç ve hangi bilgiyle netleşeceğini yaz.

| Tier | Yürütme | Zorunlu ajanlar |
|---|---|---|
| 1 | `native_fast` | Yok. Orkestra Şefi doğrudan çözer, öz denetimle kapatır. |
| 2 | `orchestrated_research_worker_verifier` | researcher → worker → verifier |
| 3 | `full_army_with_security_audit` | researcher → worker → verifier + security-auditor |

Tier 1 koşulu: tek dosya, 30 dakikadan az, kök neden kanıtlanmış, düşük risk ve geri alınabilir.
Ratchet: gizli bir bağımlılık veya veri, maliyet veya üretim etkisi çıkarsa kademe yalnız yukarı gider. Gerekçeyi ve eklediğin ajan ile testi kaydet.

## 2. Alt görev zarfı

Alt ajan çağırırken dokuz alanı doldur. Eksik alan varsa çağırma.

| Alan | İçerik |
|---|---|
| Kimlik | Görev ID, ajan adı, amaç, Tier |
| Bağlam | Kök neden bulgusu, plan, ilgili dosyalar, geçerli kurallar |
| Girdi | Base revision, sözleşme ID ve sürüm |
| Yazma kapsamı | Kesin izinli yollar; ortak dosyanın sahibi |
| Yetki | Araç ve izin sınırları, ortam, yasak yan etkiler |
| Teslim | Test edilebilir çıktı ve rapor yeri |
| Kabul | Test ID, komut, beklenen sonuç |
| Bütçe | İşlem, süre ve deneme sınırı ile kontrol noktası |
| Süreç | Cwd, dal, açık süreç kimlikleri, entegrasyon sahibi |

Alt ajan kapsamını veya yetkisini kendi genişletmez; gerekçeyi koordinatöre yazar. Sohbet geçmişini, tüm kaynak kodu ve secret'ı devretme.
Keşif ajanını yalnız bağımsız araştırmanın faydası maliyetini karşıladığında kullan. Küçük bir aramayı sırf "keşif" diye delege etme.

## 3. Dosya sahipliği ve eşzamanlılık

- Her yazılabilir dosyaya tek sahip ata. Aynı dosya üzerinde eşzamanlı iki yazıcı olmaz.
- Ortak `package.json`, `pubspec.yaml`, lockfile, şema, migration, tasarım tokenları ve `AGENTS.md` tek sahiplidir. Koordinatör bu sahipliği kendisi atar.
- İzin sistemi işçinin bu dosyaları düzenlemesini zaten engeller. Engeli aşan ajan kuralı baypas etmiş sayılır; kapsamı daralt veya koordinatöre bildir.
- Ana ajan dahil toplam aktif ajan en fazla 3. Bekleyen işçi aktif sayılır, işi kapanınca sayılmaz. Ortamın daha düşük sınırı geçerlidir.
- Alt ajan alt ajan başlatmaz. Delegasyon derinliği 1'dir.
- Model seçimi varsayılan olarak ebeveynden miras alınır; fiyat veya kalite varsayımıyla gizlice farklı modele geçilmez.

Ortak API, olay veya veri şeması değişiyorsa işçileri başlatmadan önce sözleşmeyi sabitle: kimlik, tüketiciler, giriş ve çıkış, hata davranışı, yetki, tekilleştirme, kaynak sınırı, veri ömrü, uyumluluk, kanıt. Durumlar DRAFT → REVIEWED → ACCEPTED → SUPERSEDED. ACCEPTED yalnız gerçek kabul kaydı, tarih ve revizyonla yazılır.

## 4. Kanıt kapısı

Her kontrol kanıtında zorunlu alanlar:
Görev ID; tam commit SHA veya base + patch/dosya hash manifesti; komutun tam metni; cwd; ortam ve araç sürümü; UTC zaman; exit code; toplam ve atlanan test sayısı; maskelenmiş log veya rapor yolu.

Kurallar:
- Derleme veya izole birim testinin geçmesi tek başına yeterli değildir. Gerçek kontrol komutları ve uçtan uca akış doğrulanır.
- Atlanan, keşfedilmeyen veya çalıştırılamayan kontrol PASS olmaz.
- "0 test bulundu" başarı kanıtı değildir.
- `CHECKS.md` içinde olmayan bir komut çalıştırılmış gibi gösterilmez.
- Terminal rengi ve ekran görüntüsü tek başına kanıt değildir.
- Beklenen ilk kırmızı TDD testi doğru sebeple başarısız olduğunda geliştirme kanıtıdır. Yayın kapısı için son ilgili test PASS olmalıdır.
- İnceleme sonrası kaynak değiştiyse önceki PASS geçersizleşir. Entegrasyon revizyonu ayrıca ilgili testten geçer.
- Aynı ajan hem yaptı hem onayladıysa o iş bağımsız incelenmiş sayılmaz. "Rol değiştirdim" bağımsızlık sağlamaz.
- Tier 3 yayınında bağımsız doğrulama ve güvenlik denetimi yapılamıyorsa kapı BLOCKED kalır. Hazırlık sürdürülebilir, yayın yapılmaz ve yapılmayan inceleme açıkça bildirilir.

## 5. Devre kesici

Hata parmak izi = kontrol veya test ID + kök hata sınıfı + etkilenen bileşen.
Başarısız deneme, aynı sorunu çözmek için yapılan anlamlı değişiklik ve ardından gelen başarısız doğrulamadır. Beklenen ilk kırmızı TDD testi ve yalnız log okuma sayılmaz.

Tetikleyici ve tepki:
- Aynı parmak izinde 3 başarısız deneme: dur, teşhis yaz, farklı plan kur.
- 30 araç işlemi veya 15 dakika: dur, kanıtlı kontrol noktası ver.
- Yetkisiz erişim, sır açığa çıkması, kullanıcı verisi riski: derhal dur, etkiyi sınırla.
- Beklenmeyen üretim, maliyet veya yan etki: dur, kapsamı bildir.
- Araç veya erişim eksikliği: BLOCKED. Sahte tekrar döngüsü kurma.

Durduğunda:
- Yeni yazma ve yan etkiyi kes. Yalnız görevine ait süreçleri durdur, adı eşleşen ortak süreçleri topluca sonlandırma.
- Cwd, revision, kirli envanter, log ve test sonucunu koru.
- Kullanıcı değişiklikleriyle kendi değişikliklerini ayır. Sahiplik belirsizse geri alma yapma.
- Doğrulanacak hipotezi ve sıradaki en küçük adımı yaz.
- Güvenli ileri düzeltme, kapsamlı geri dönüş veya izolasyonda bekletme seçeneklerinden birini seç ve gerekçelendir.

Yeniden başlama koşulu: hipotez değişmiş, kabul ölçütü açık, gerekli erişim mevcut, yeni kaynak bütçesi kayıtlı. Aynı yamayı başka ajana vermek yeni yaklaşım sayılmaz.

Yasak kurtarma: `git reset --hard`, `git clean -fd`, toplu restore, kapsamı belirsiz özyinelemeli silme. Başarısız test otomatik rollback gerekçesi değildir. Devre kesilmesi otomatik dosya silme anlamına gelmez.

Durumlar: READY → RUNNING → PAUSED veya TRIPPED → RECOVERING → RUNNING veya CLOSED. Bütçe yenileme eski sayacı silmez.

## 6. Kapanış raporu

Her teslimde şu sırayla yaz:
Durum (PLANNED, READY, RUNNING, BLOCKED, IN_REVIEW, DONE, FAILED, STOPPED); yapılan iş ve sağlanan davranış; base SHA ve tam commit SHA veya hash manifesti; değişen dosya yolları; sözleşme ID ve sürümü veya gerekçeli N/A; komut, cwd, UTC, ortam sürümü, exit code ve test sayısı; kontrol sonucu (NOT_RUN, PASS, FAIL, BLOCKED, N/A) ve rapor yolu; çalıştırılmayan kontroller ve kapsam dışı alanlar; açık risk, açık süreç ve geri dönüş seçeneği; sonraki tek adım.

Kontrol sonucu sözlüğü: `NOT_RUN` çalışmadı, `PASS` ölçüt sağlandı, `FAIL` ölçüt sağlanmadı, `BLOCKED` araç veya ortam eksikliği, `N/A` uygulanamaz ve gerekçesi yazılır.

Rapor kuralları: test edilmemiş sonucu, örnek sayıyı veya şablon durumunu gerçekmiş gibi gösterme. Önceki FAIL'dan sonra PASS varsa iki revizyonu ayır. Ham kod veya log ekleme, maskelenmiş referans ver. Token, sır veya kişisel belge içeriği ekleme. "Geri alındı" yalnız geri alma gerçekten uygulanıp doğrulandıysa yazılır.

## 7. Kurulum notları

- Hedef projeye yalnız `.opencode/` altındaki ajan, beceri ve komut dosyaları kopyalanır. `.agents/` klasörü kopyalanmaz: depoyu kirletir ve ikinci kaynak oluşturur. Gerekirse tek bir `AGENTS.md` bloğu ile `umaf` becerisi yeterlidir.
- Politika metni buraya yazıldığı için config'de `instructions` alanı bilerek boş bırakılmıştır. Politikayı her turda yüklemek token israfıdır; bu beceri `skill` aracıyla çağrıldığında gövde konuşmaya eklenir.
- Görev kaydı ve görev indeksi yalnız Tier 3'te zorunludur. Tier 1 ve Tier 2'de görev, kabul ölçütü, dosya sahipliği ve sonuç oturum içinde izlenir; repo'ya görev dosyası yazılmaz. Yazılırsa tek yazarı yine koordinatördür.
- Ayrıntılı politika, şablon ve iş akışı gerektiğinde `.agents/` altındaki belgelere git: `policies/risk.md`, `policies/quality.md`, `policies/security.md`, `policies/contracts.md`, `policies/orchestration.md`, `workflows/recovery.md`, `workflows/isolation.md`, `templates/task.md`.