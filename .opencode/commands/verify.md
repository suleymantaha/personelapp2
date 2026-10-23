---
description: CHECKS.md içindeki gerçek komutları tanımlı sırayla çalıştırır, kanıt tablosu üretir ve PASS/FAIL/BLOCKED/NOT_RUN kararı verir.
subagent: false
---

Aşağıdakileri sırayla yap. Adım atlamaz, tahmin yazmaz, komut uydurmaz.

HEDEF KAPSAM:
$ARGUMENTS

1. Depo kökünde `CHECKS.md` dosyasını oku ve listelenen gerçek komutları çıkar. Dosyada olmayan bir script'i "örnek" diye uydurma ve tahmini komut çalıştırma. Dosyada karşılığı olmayan bir kontrol bu görevde `NOT_RUN` olur.
2. Her komut için `CHECKS.md` içinde yazan cwd'yi kullan. Farklıysa farkı kanıt tablosuna not olarak yaz.
3. Komutları tanımlandıkları sırayla çalıştır. Bir komut çalışmazsa `BLOCKED` de ve hata metnini kısa alıntıyla ver; zinciri kesme.
4. Komutun dış veritabanına, ödeme sistemine veya üretim servisine yazıp yazmadığını çalıştırmadan önce kontrol et. Şüpheliyse çalıştırma ve `BLOCKED` de.
5. Test sayısı çıktısını gerçekten oku. "0 test bulundu" PASS kanıtı değildir; `N/A` veya `FAIL` olarak değerlendir ve nedenini yaz.

KANIT TABLOSU — her kontrol için bir satır:
| Kontrol | Komutun tam metni | cwd | Araç ve ortam sürümü | UTC zaman | Exit code | Sonuç | Test sayısı | Not |

SONUÇ SÖZLÜĞÜ — her kontrol için tam olarak biri:
- `NOT_RUN`: kontrol çalışmadı.
- `PASS`: tanımlanmış ölçüt gözlenen sonuçla sağlandı.
- `FAIL`: ölçüt sağlanmadı.
- `BLOCKED`: araç, erişim, bağımlılık veya ortam eksikliği nedeniyle tamamlanamadı; başarı da hata da varsayma.
- `N/A`: bu değişiklik için uygulanamaz; gerekçesini yaz.

KURALLAR:
- Atlanan, keşfedilmeyen veya çalıştırılamayan kontrol PASS olmaz.
- Derleme veya izole birim testinin geçmesi tek başına yeterli değildir; uçtan uca akışı da doğrula.
- Ham logu yanıta dökme. Maskelenmiş artifact yolunu ver. Logda sır veya kişisel belge varsa önce maskele.
- Terminal rengi veya ekran görüntüsü tek başına kanıt değildir.
- Uygulama kaynak kodunu değiştirme. Bulduğun hatayı `dosya:satır` ile bildir, kalıcı düzeltme yapma.
- `git reset --hard` ve `git clean` çalıştırma.

KAPANIŞTA AYRICA YAZ:
- Kapsam dışı bırakılan alanlar.
- Çalıştırılmadığı için bilinmeyenler.
- Engeller ve gerçek engelin kaynağı.
- Tek bir sonraki adım.