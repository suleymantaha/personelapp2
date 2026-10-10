# Kanıta dayalı kalite kapısı — Universal Agent Kit 1.0

Paket sürümü: 1.0 · 10 Ekim 2026.

Bir kontrolün çalıştırılmış olması, beklenen sonucu verdiği anlamına gelmez. Başarı iddiası yalnız gerçekten incelenen revizyon, kapsam ve ortam için yapılır.

## 1. Sonuç sözlüğü

| Sonuç | Anlam |
|---|---|
| NOT_RUN | Kontrol henüz çalışmadı |
| PASS | Tanımlanmış ölçüt gözlenen sonuçla sağlandı |
| FAIL | Ölçüt sağlanmadı |
| BLOCKED | Araç, erişim, bağımlılık veya ortam nedeniyle tamamlanamadı |
| N/A | Bu değişiklik için uygulanabilir değil; gerekçe kayıtlı |

Atlanan, keşfedilmeyen veya çalıştırılamayan test PASS olmaz. “0 test bulundu” başarı kanıtı değildir. Beklenen ilk TDD FAIL'i, doğru sebeple başarısız olduğunda geliştirme kanıtıdır; yayın kapısı için son ilgili test PASS olmalıdır.

## 2. Her kanıtta gerekenler

Görev ID; commit SHA veya base + patch/dosya hash manifesti; komutun tam biçimi; cwd; ortam/araç sürümü; UTC zaman; exit code; test sayısı ve atlananlar; maskelenmiş log/rapor yolu.

Uzun ham log kullanıcı yanıtına dökülmez; güvenli artifact'ta saklanabilir. Sır/kişisel dosya içeriyorsa önce maskele. Terminal yeşil rengi veya bir ekran görüntüsü tek başına yeterli değildir.

## 3. Değişime göre kontroller

| Değişiklik | Asgari uygun doğrulama |
|---|---|
| Salt okunur araştırma | Kaynak/konum, tarih, olgu-varsayım ayrımı |
| Doküman/şablon | Bağlantı, alan, komut ve belgeler arası tutarlılık |
| Davranış değişimi | İlgili birim/regresyon ve gerekiyorsa build |
| Ortak API/şema | Üretici+tüketici sözleşme ve hata testleri |
| Güvenlik/ödeme/veri | Olumsuz durum, yetki, yarış, geri dönüş ve bağımsız inceleme |
| Yayın | Tam gerekli CI, ortam smoke, artifact revision ve rollback |

Başlangıçta var olan uyarılar ve test hataları kaydedilir. Yeni hata/regresyon kabul edilmez. Önceden bilinen bir uyarı nedeniyle ilgisiz kod temizliğine sınırsız kapsam açılmaz. Mevcut CI sıfır uyarı şartı koyuyorsa aynen uygulanır; düzeltilemeyen engel saklanmaz.

## 4. Komut eşlemesi

Aşağıdakiler otomatik çalıştırılacak evrensel komut listesi değildir. Projenin package scripts, CI ve build hedeflerinden gerçek komut seçilir.

| Ekosistem | Kontrol örneği | Sınır |
|---|---|---|
| TypeScript | package script ile lint, typecheck, test, build | tsc tip kontrolü uygulama paketlemesi değildir |
| Python | ruff check; pytest; yapılandırılmışsa mypy | pytest linter değildir; paket testi ayrıca gerekebilir |
| Go | go test ./...; go build ./... | Linter projede mevcutsa kullan |
| Rust | cargo test; cargo check; yapılandırılmış clippy | cargo check dağıtım artifact'ı değildir |
| Flutter | flutter analyze; flutter test; hedefe uygun build | Genel bir build dry-run bayrağı varsayma; kurulu CLI yardımını doğrula |
| Java/Kotlin | Projedeki Gradle/Maven görevleri | Wrapper ve eklenti görevleri gerçekten var mı kontrol et |
| .NET | dotnet test; dotnet build; yapılandırılmış format kontrolü | SDK ve platform hedefiyle eşleştir |

Çalıştırılacak gerçek komut, kabul koşuluyla birlikte görev defterine yazılır. Olmayan script “örnekti” denilerek PASS gösterilmez.

## 5. Bağımsız doğrulama

İşçi önce kendi testini çalıştırır; bağımsız denetçi uygulayıcıdan farklı bir ajan veya kişidir. Aynı ajanın yalnız rol değiştirmesi bağımsızlık sağlamaz. Denetçi uygulama kaynağını değiştirmez. Testin oluşturduğu çıktı/cache yalnız kendisine ayrılan geçici alanda olabilir.

Sabit commit veya hash manifesti incelenir. İnceleme sonrası değişiklik etkilenen kanıtı geçersizleştirir. Entegrasyon commit'i ayrıca uygun testten geçer. Farklı worktree'de aynı dal adını görmek aynı byte'ları test etmek demek değildir.

Tier 3 yayınında bağımsız inceleme imkânı yoksa kapı BLOCKED olur. Hazırlık ve yerel test sürdürülebilir; kullanıcıya yapılmayan inceleme açıkça bildirilir.

## 6. Kapanış

DONE için gerekli kontroller PASS veya gerekçeli N/A olmalı, açık yayın engeli bulunmamalı. Görev kapsamı yalnız hazırlıksa yayın gerekmeyebilir. Rapor hem doğrulanmış sonucu hem kontrol dışındaki alanları belirtir.

[Denetçi rolü](../roles/verifier.md) · [Rapor şablonu](../templates/report.md)

Ortak varsayılanlar [framework.json](../framework.json) dosyasındadır; üst düzey talimatlar ve ortam kapasitesi önceliklidir.
