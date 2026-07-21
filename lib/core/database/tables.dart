import 'package:drift/drift.dart';

/// 1. Kullanıcı Tablosu
class KullaniciTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kullaniciAdi => text().unique()();
  TextColumn get sifre => text()();
  TextColumn get rol => text()(); // 'yönetici' veya 'tim_komutani'
  IntColumn get timId => integer().nullable().references(TimTable, #id)();
}

/// 2. Tim Tablosu
class TimTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get timAdi => text()();
  IntColumn get timKomutaniId =>
      integer().nullable().references(KullaniciTable, #id)();
  TextColumn get olusturmaTarihi => text()();
}

/// 3. Personel Tablosu
class PersonelTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get adSoyad => text()();
  TextColumn get rutbe => text()();
  TextColumn get birlik => text()();
  IntColumn get timId => integer().nullable().references(TimTable, #id)();
  TextColumn get kayitTarihi => text()();
}

/// 4. Günlük Faaliyet Tablosu
class GunlukFaaliyetTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get faaliyetAdi => text()();
  TextColumn get tarih => text()(); // YYYY-AA-DD
  TextColumn get olusturanKullanici => text()();
  TextColumn get olusturmaTarihi => text()();
}

/// 5. Faaliyet-Personel Atama Tablosu
class FaaliyetPersonelAtamaTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get faaliyetId =>
      integer().references(GunlukFaaliyetTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get personelId =>
      integer().references(PersonelTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get gorevVeyaIzin =>
      text()(); // 'GÖREVLİ', 'NÖBETÇİ', 'İZİNLİ', 'İSTİRAHATLİ', 'RAPORLU', 'SEVK'
  TextColumn get durum => text()(); // 'onaylandi', 'beklemede', 'reddedildi'
  TextColumn get aciklama => text().nullable()();
}

/// 6. Rapor Kayıt Tablosu
class RaporKayitTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personelId =>
      integer().references(PersonelTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get raporBaslangic => text()(); // YYYY-AA-DD
  TextColumn get raporBitis => text()(); // YYYY-AA-DD
  TextColumn get aciklama => text().nullable()();
}

/// 7. Tim Üyelik Geçmişi Tablosu
class TimUyelikGecmisiTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personelId => integer()();
  IntColumn get timId => integer().nullable().references(TimTable, #id)();
  TextColumn get tarih => text()(); // YYYY-AA-DD
  TextColumn get islem => text()(); // 'eklendi', 'çıkarıldı'
}

