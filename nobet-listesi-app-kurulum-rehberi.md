# Günlük Faaliyet / Nöbet Listesi Yönetim Uygulaması — Kurulum Rehberi

## 1. Projenin Amacı

Elle Excel/Word üzerinde hazırlanan günlük faaliyet-personel listelerini:
- Mobil uygulama üzerinden dijital olarak girmek,
- Tim komutanlarından bildirim/veri toplamak,
- Tek merkezi kayıt (arşiv) altında tutmak,
- İstenildiğinde Excel çıktısı ve paylaşılabilir metin/PDF olarak üretmek

amacıyla kapalı (yerel/özel) bir sistem kurmak.

---

## 2. Genel Mimari

```
[Flutter Mobil Uygulama]  <---->  [Yerel Sunucu / Backend]  <---->  [Veritabanı]
   (Tim Komutanları)              (Kendi bilgisayarınız/          (SQLite veya
                                    kurum sunucusu, internete       PostgreSQL)
                                    açık olmak zorunda değil)
```

- **Frontend:** Flutter (Android + iOS tek kod tabanından)
- **Backend:** Yerel ağda çalışan basit bir API sunucusu (öneri: **Node.js + Express** veya **Python + FastAPI**)
- **Veritabanı:** Küçük ölçek için **SQLite**, büyürse **PostgreSQL**
- **Dağıtım:** Uygulama app store'a değil, doğrudan `.apk` dosyası olarak dağıtılır (kapalı devre)
- **Ağ:** Kurum içi Wi-Fi / VPN üzerinden erişim — internete açık olmasına gerek yok

---

## 3. Veritabanı Yapısı (Tablolar)

### 3.1 `personel` (Sabit Kadro)
| Alan | Tip | Açıklama |
|---|---|---|
| id | INTEGER (PK) | Otomatik artan |
| ad_soyad | TEXT | Personel adı soyadı |
| rutbe | TEXT | Örn: J.UZM.ÇVŞ, ASB, SB |
| birlik | TEXT | Örn: Nöb Heyeti, KH, 3'üncü Bl. |
| aktif | BOOLEAN | Kadroda aktif mi |

### 3.2 `faaliyet` (Günlük Faaliyet Başlığı)
| Alan | Tip | Açıklama |
|---|---|---|
| id | INTEGER (PK) | Otomatik artan |
| tarih | DATE | Faaliyet tarihi |
| ad | TEXT | Örn: "Heybet Tepe Pusu Faaliyeti" |
| olusturan_kullanici | TEXT | Girişi yapan komutan |

### 3.3 `faaliyet_personel` (Günlük Atama Detayı)
| Alan | Tip | Açıklama |
|---|---|---|
| id | INTEGER (PK) | Otomatik artan |
| faaliyet_id | INTEGER (FK) | faaliyet tablosuna bağlı |
| personel_id | INTEGER (FK) | personel tablosuna bağlı |
| gorev | TEXT | Örn: NÖB.SB, MEBS NÖB, HAZIR KITA |
| sira_no | INTEGER | Listedeki sıra numarası |

### 3.4 `kullanici` (Giriş Yapan Tim Komutanları)
| Alan | Tip | Açıklama |
|---|---|---|
| id | INTEGER (PK) | Otomatik artan |
| kullanici_adi | TEXT | Giriş kullanıcı adı |
| sifre_hash | TEXT | Şifrelenmiş şifre |
| yetki | TEXT | admin / tim_komutani |

---

## 4. Backend Kurulumu (Node.js + Express + SQLite örneği)

### 4.1 Gerekli Araçlar
- Node.js (LTS sürüm) kurulu bir bilgisayar/sunucu
- `npm install express sqlite3 bcrypt jsonwebtoken cors`

### 4.2 Klasör Yapısı
```
/backend
  /db
    veritabani.sqlite
  /routes
    personel.js
    faaliyet.js
    auth.js
  server.js
  package.json
```

### 4.3 Temel API Uç Noktaları (Endpoints)
| Metod | Yol | Açıklama |
|---|---|---|
| POST | /auth/login | Kullanıcı girişi, token döner |
| GET | /personel | Kadro listesini getirir |
| POST | /personel | Yeni personel ekler |
| POST | /faaliyet | Yeni günlük faaliyet oluşturur |
| GET | /faaliyet/:tarih | Belirli tarihin listesini getirir |
| GET | /faaliyet/arsiv | Tüm geçmiş kayıtları listeler |
| GET | /faaliyet/:id/export | Excel (.xlsx) çıktısı üretir |

### 4.4 Sunucuyu Çalıştırma
```bash
cd backend
npm install
node server.js
```
Sunucu, kurum içi ağda örn. `http://192.168.1.50:3000` adresinde çalışır. Flutter uygulaması bu adrese bağlanır (internet gerekmez, sadece aynı Wi-Fi/ağ).

---

## 5. Flutter Uygulaması Kurulumu

### 5.1 Gerekli Araçlar
- Flutter SDK (flutter.dev üzerinden indirilir)
- Android Studio veya VS Code
- `flutter doctor` komutu ile kurulumu doğrulayın

### 5.2 Proje Oluşturma
```bash
flutter create nobet_listesi_app
cd nobet_listesi_app
```

### 5.3 Gerekli Paketler (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0            # Backend'e istek atmak için
  provider: ^6.1.0        # State management
  shared_preferences: ^2.2.0  # Giriş bilgisi/token saklama
  share_plus: ^7.2.0      # WhatsApp/Telegram paylaşımı
  excel: ^4.0.0           # Excel dosyası oluşturma (opsiyonel, yerelde de üretebilirsiniz)
```

### 5.4 Ekran Listesi (Sayfa Yapısı)
```
/lib
  main.dart
  /screens
    login_screen.dart          # Kullanıcı adı/şifre girişi
    kadro_screen.dart          # Sabit personel listesi (ekle/düzenle)
    yeni_faaliyet_screen.dart  # Tarih seç + personel ata
    gunluk_liste_screen.dart   # Günün listesini görüntüle + paylaş
    arsiv_screen.dart          # Geçmiş kayıtları tarih bazlı listele
  /models
    personel.dart
    faaliyet.dart
  /services
    api_service.dart           # Backend ile HTTP iletişimi
```

### 5.5 Uygulamayı Çalıştırma (Test)
```bash
flutter run
```

### 5.6 Kapalı Dağıtım (App Store'a Yayınlamadan)
```bash
flutter build apk --release
```
Oluşan `.apk` dosyasını doğrudan tim komutanlarına WhatsApp/USB/kurum içi paylaşım aracıyla gönderirsiniz. Google Play'e yüklemeden, telefonlarına "bilinmeyen kaynaklardan yükleme" izniyle kurarlar.

---

## 6. Paylaşım Akışı (Tim Komutanı Açısından)

1. Uygulamayı açar, kullanıcı adı/şifre ile giriş yapar.
2. "Yeni Faaliyet" ekranından tarih ve kendi biriminin personelini seçip görev atar.
3. "Kaydet" der → veri backend'e, oradan veritabanına yazılır.
4. Aynı ekrandan "Paylaş" butonuna basarak WhatsApp/Telegram/SMS'e otomatik metin gönderebilir.
5. Siz (admin) "Arşiv" ekranından tüm birimlerin o günkü girişlerinin **birleşmiş halini** görürsünüz — elle toplama gerekmez.

---

## 7. Excel Çıktısı Alma

- Backend'de `GET /faaliyet/:id/export` isteği, `exceljs` (Node.js) veya `openpyxl` (Python) kütüphanesi ile mevcut formatınıza (S.NU / Birliği / Rütbe / Adı Soyadı / Diğer) birebir uyumlu `.xlsx` dosyası üretir.
- Bu dosya hem admin panelinden hem Flutter uygulamasından indirilebilir.

---

## 8. Görev Takip Listesi (Aylık/Yıllık X İşaretli Takvim)

### 8.1 Amaç
Her personelin hangi gün(ler) görev yaptığını ve toplam kaç gün görev yaptığını gösteren, satırların personel, sütunların günler (1-31) olduğu bir takip tablosu — Excel ve PDF olarak indirilebilir.

### 8.2 Neden İsim Çakışması Sorun Olmaz
Sistemde personel **isim (metin) ile değil, benzersiz `personel_id` ile** takip edilir:
- Tim komutanı günlük faaliyet girerken personeli **kadrodan seçer** (dropdown), serbest metin yazmaz.
- `faaliyet_personel` tablosu her kaydı `personel_id` + `tarih` ikilisiyle tutar.
- Aynı isimde iki farklı personel olsa bile (örn. iki "Mehmet Kaya"), her biri farklı `id`'ye sahip olduğundan takip tablosunda karışmaz — her biri kendi satırında ilerler.
- **Kritik kural:** Flutter tarafında personel seçim ekranlarında her zaman "kadrodan seç" (ID bağlı) bileşeni kullanılmalı, elle isim girişine izin verilmemeli.

### 8.3 Takip Tablosu Üretim Mantığı
Backend'de şu sorgu mantığıyla üretilir:
```sql
SELECT p.id, p.ad_soyad, p.rutbe, p.birlik,
       fp.faaliyet_tarihi
FROM personel p
LEFT JOIN faaliyet_personel fp ON fp.personel_id = p.id
WHERE fp.faaliyet_tarihi BETWEEN '2026-07-01' AND '2026-07-31'
```
Bu sonuç, personel × gün matrisine (pivot) dönüştürülür: personelin göründüğü her tarihe "X" konur, TOPLAM GÜN sütunu `COUNTIF` benzeri bir sayımla otomatik hesaplanır.

### 8.4 Excel/PDF Şablonu
Örnek çalışan şablon iki dosya halinde üretildi:
- `gorev_takip_sablonu.xlsx` — "Aylık Takip" (X işaretli, gün sütunlu, formüllü toplam) + "Yıllık Özet" (ay ay toplamlar, formülle bağlı) sayfaları
- `gorev_takip_sablonu.pdf` — aynı tablonun yazdırılabilir/paylaşılabilir PDF hâli

Flutter/backend entegrasyonunda bu şablon, `openpyxl` (Python backend) veya eşdeğer bir Node.js kütüphanesi (`exceljs`) ile **her ay otomatik güncellenip** aynı formatta üretilecek şekilde kurulur — elle X işaretlemeye gerek kalmaz, sistem faaliyet kayıtlarından otomatik doldurur.

### 8.5 Takip Sayfasının Kadroyla Otomatik Güncel Kalması

Takip sayfası sabit/statik bir dosya değil, **her istendiğinde o anki kadrodan yeniden üretilen** bir rapor olmalı — böylece admin yeni personel eklediğinde veya birini timden çıkardığında elle satır ekleyip çıkarmaya gerek kalmaz.

**Neden basit bir "katılma tarihi / ayrılma tarihi" alanı yetersiz kalır:**
Personel zaman zaman aynı timden çıkıp tekrar aynı time dönebiliyorsa (izin, geçici görevlendirme vb.), tek bir tarih çifti bu döngüyü tutamaz — ikinci girişte veri kaybolur veya yanlış görünür.

**Çözüm: Üyelik Geçmişi (Event Log) Tablosu**

Yeni tablo: `tim_uyelik_gecmisi`
| Alan | Açıklama |
|---|---|
| id | Benzersiz numara |
| personel_id | Kime ait |
| tim_id | Hangi time |
| tarih | Ne zaman oldu |
| islem | `eklendi` veya `çıkarıldı` |

- Bir personel bir time her eklendiğinde/çıkarıldığında buraya yeni bir satır düşer — mevcut kayıt üzerine yazılmaz.
- Takip sayfası üretilirken, belirli bir tarih için "bu kişi o gün bu timde aktif miydi?" sorusu, o tarihten önceki **en son olaya** (`eklendi` mi `çıkarıldı` mı) bakılarak otomatik hesaplanır.
- Personel birden fazla kez aynı time girip çıksa bile veri kaybı veya karışıklık olmaz.
- Aynı tablo, "kim ne zaman hangi time atandı/ayrıldı" sorusuna da tam bir **denetim izi (audit trail)** sağlar.

**Karşılaştırma:**

| | Tek tarih alanı (`katilma_tarihi`) | Olay günlüğü (`tim_uyelik_gecmisi`) |
|---|---|---|
| Tek seferlik katılım | Yeterli | Yeterli |
| Birden fazla giriş-çıkış | Yetersiz, veri kaybı olur | Sorunsuz |
| Geçmiş sorgulama | Sınırlı | Tam detaylı |

Bu tablo sayesinde geçmiş kayıtlar hiçbir zaman değişmez (bkz. Bölüm 9.4 "Geçmişin değişmesi" riski), yeni personel otomatik olarak eklendiği tarihten itibaren takip sayfasında belirir, ayrılan personelin geçmiş kayıtları korunur.

---

## 9. Tim Yapısı ve Onay İş Akışı (Approval Workflow)

### 9.1 Yeni Tablo: `tim`
| Alan | Tip | Açıklama |
|---|---|---|
| id | INTEGER (PK) | Benzersiz numara |
| tim_adi | TEXT | Admin'in verdiği isim, örn. "1B Timi" |
| komutan_kullanici_id | INTEGER (FK) | Bu timi yönetecek komutanın giriş hesabı |

`personel` tablosuna `tim_id` (FK) eklenir. Tim oluşturma/personel atama **sadece admin** panelinde yapılır; tim komutanı sadece kendi timinin günlük durumunu günceller.

### 9.2 `faaliyet_personel` Tablosuna Eklenecek Alanlar
| Alan | Tip | Açıklama |
|---|---|---|
| durum | TEXT | `beklemede` / `onaylandi` / `reddedildi` |
| tim_id_snapshot | INTEGER | O günkü tim bilgisinin **sabit kopyası** (canlı `tim_id`'ye değil, o ana ait değere bağlı — aşağıya bakınız) |
| versiyon | INTEGER | Aynı gün/tim için kaç kez güncellendiği |
| gonderim_zamani | DATETIME | Ne zaman gönderildiği |

### 9.3 Günlük Akış
```
[ADMIN]    Tim oluşturur → Personelleri bu time atar → Komutan atar
[KOMUTAN]  Giriş yapar → sadece kendi timinin listesi gelir (varsayılan: hepsi "dahil")
           → o gün eksik olanları (izinli/raporlu/başka görevde) kapatır → "Gönder"
[SİSTEM]   Otomatik kontrol eder:
             - Kadroda olmayan personel var mı?
             - Aynı personel aynı gün başka bir timde de aktif mi?
             - Personelin izinli/raporlu kaydı bu tarihle çakışıyor mu?
           Çakışma YOKSA  → otomatik "onaylandı", takip tablosuna işlenir, admin'e BİLGİ bildirimi gider
           Çakışma VARSA  → "onay bekliyor" listesine düşer, FCM ile admin uyarılır
[ADMIN]    Gerekirse elle düzeltme yapar (bu düzeltme "admin_duzeltmesi" olarak ayrıca işaretlenir)
```

### 9.4 Dikkat Edilmesi Gereken Mantık Noktaları (ve Çözümleri)

| Risk | Neden Sorun Olur | Çözüm |
|---|---|---|
| **Geçmişin değişmesi** | Personel bir timden başka bir time taşınırsa, canlı `tim_id` bağlantısı geçmiş ayların raporunu da değiştirir | Her `faaliyet_personel` kaydı, o günkü tim bilgisini **anlık kopya (`tim_id_snapshot`)** olarak saklar — geçmiş asla geriye dönük değişmez |
| **"Gönderilmedi" ile "herkes var" karışması** | Komutan o gün hiç giriş yapmazsa, sistem sessizce "herkes görevde" varsayarsa yanlış veri oluşur | Gönderim yoksa durum açıkça **"gönderilmedi"** kalır, otomatik "herkes var" işaretlenmez; gün sonunda admin'e "eksik gönderim" bildirimi gider |
| **Aynı anda çakışan iki gönderim** | İki komutan aynı anda aynı personeli gönderirse, çakışma kontrolü ikisini de görmeden geçebilir | Çakışma kontrolü kayıt anında **atomik** (veritabanı transaction'ı içinde) yapılır, sıralı işlenir |
| **Onaylı günün sonradan değişmesi** | Onaylanmış bir gün değiştirilirse, daha önce üretilmiş Excel/PDF çıktılarıyla güncel veri tutarsız hale gelir | Her onay bir **versiyon numarası** alır; eski PDF/Excel çıktıları "v1", yeni değişiklik "v2" gibi ayrı ayrı işaretlenir |
| **Otomatik onayın belirsizliği** | "Çakışma yok" tanımı net değilse, otomatik onay ya çok gevşek ya çok sıkı çalışır | Otomatik onay kuralları en baştan yazılı ve sabit 3 kural olarak tanımlanır (kadro dışı personel yok, çift tim ataması yok, izinli/raporlu çakışması yok) — bunlar dışında her şey otomatik geçer |

---

## 10. Güvenlik ve Kapalılık Notları

- Backend yalnızca kurum içi ağda (yerel IP) çalıştırılmalı, internete port yönlendirmesi yapılmamalı.
- Kullanıcı şifreleri `bcrypt` ile hash'lenmeli, düz metin saklanmamalı.
- Uygulama `.apk` olarak dağıtıldığından hiçbir üçüncü taraf mağazasına (Play Store) yüklenmez.
- Düzenli yerel yedekleme (veritabanı dosyasının haftalık kopyası) önerilir.

---

## 11. Uygulama Geliştirme Sırası (Yol Haritası)

1. Backend + veritabanı tablolarını kur, temel API'leri test et (Postman ile).
2. Flutter'da giriş ekranı + kadro listesi ekranını yap.
3. Günlük faaliyet oluşturma ve personel atama ekranını ekle.
4. Paylaşım (share_plus) ve Excel export özelliğini bağla.
5. Arşiv/takip ekranını ekle, tarih filtresi koy.
6. `.apk` üretip test cihazlarına dağıt, tim komutanlarından geri bildirim al.

---

## 12. Önerilen Sonraki Adım

Bu md dosyasını temel alarak, önce **backend + veritabanı** kısmını birlikte kod olarak yazmaya başlayabiliriz, ya da önce **Flutter ekran tasarımlarını** (arayüz) netleştirebiliriz. Büyük ölçekli bir kod projesi olduğundan, gerçek kodlamayı **Claude Code** üzerinden adım adım ilerletmeniz en sağlıklısı olur; bu dosya o sürecin yol haritası olarak kullanılabilir.
