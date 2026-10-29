# Birleşik çıktı önizlemesi ve 21+ X hariç tutma

| Alan | Değer |
|---|---|
| Görev ID | 2026-10-28-roster-matrix-x-exclusion |
| Amaç | İkinci ekranı modernleştirmek ve seçilen ayda 21+ X olanları kurallı çıktıya almamak; kalanları rütbe sırasına koymak |
| Tier | 2, çok dosyalı UI ve veri kuralı |
| Yetki | Yerel uygulama; APK/Drive/CI/commit/push istenmedi |
| Koordinatör | Kök ajan, tek kod ve defter yazarı |
| Repo/dal | F:/personelapp2, main |
| Başlangıç değişiklikleri | Önceki turdaki rütbe çıktısı ve 10319 release değişiklikleri; .playwright-cli/ ve .serena/ korunur |
| Plan | docs/superpowers/plans/2026-10-28-roster-matrix-x-exclusion.md |
| Durum | DONE |

## Kabul

| Kontrol | Durum | Kanıt |
|---|---|---|
| 20 kalır, 21+ elenir; kalanlar rütbe sıralı | PASS | Unit test ve Excel içerik testi |
| Normal ve mevcut rütbe çıktısı değişmez | PASS | Tam Flutter test paketi ve mevcut çıktı regresyonları |
| Matris yetkisi, güncelliği ve boş sonuç | PASS | Yetki kapsamı kod incelemesi; güncellik ve boş sonuç widget testleri |
| Modern ekran / dar ekran | PASS | 390x844 ve 320x568 widget testleri; ekran görüntüsünde test fontu eksik olduğundan görsel karşılaştırma sınırlı |
| Analyze, test, diff, bağımsız inceleme | PASS | `dart analyze` temiz; `flutter test --no-pub` 765 PASS, 1 skip; `git diff --check` temiz; reviewer imza kapısı bulgusunu doğruladı ve düzeltildi |

Kapsam dışı: yeni APK ve dağıtım. CI çalıştırılmadı. Cihaz üzerinde son görsel kabul yapılmadı.

## Kullanıcı netleştirmesi

20. X'ten sonraki görev ve matris işaretleri normal akışta devam eder. Seçilen ayda 21+ X olursa kişi yalnızca isteğe bağlı kurallı çıktıdan çıkar; kapalı bilgi kartında adı, rütbesi ve X günü sayısı görünür. Tam 20 X çıktıda kalır. Çıktı tarihine göre kesme uygulanmaz.

Uygulama: `RosterMatrixXResult.excludedPeople` ile seçilen kartlardan dışlanan kişiler ve X sayıları tutulur. Kapalı bilgi kartı yalnız kurallı önizlemede ve dışlanan kişi varsa gösterilir. Önizleme yenilenince kart yeniden kapanır. Matris okuma dışında değiştirilmez. İsteğe bağlı çıktı öncesinde dışlanan kişi ve X sayıları yeniden doğrulanır.

Ek doğrulama: Gün 25'te 20 X, gün 26'da 21 X senaryosu; dar telefonda kartın açılması; Excel'de dışlanan adın yokluğu. `flutter test --no-pub --reporter compact`: 767 PASS, 1 skip. Son dar kapsamlı test: 8 PASS. Değişen dosyalarda `dart analyze` ve `git diff --check` temiz. Bağımsız incelemede somut bulgu yok; gerçek repository yetki/ay sınırı uçtan uca cihaz testi yapılmadı. CI, APK, Drive, commit ve push yapılmadı.
