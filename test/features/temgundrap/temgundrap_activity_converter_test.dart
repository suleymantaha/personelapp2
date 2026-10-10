import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/temgundrap/domain/services/temgundrap_activity_converter.dart';

void main() {
  group('TemgundrapActivityConverter', () {
    final activity = GunlukFaaliyetTableData(
      id: 101,
      faaliyetAdi: 'PALU İLÇE J.K.LIĞI 09:00 - 17:00 YOL ARAMA VE EMNİYETİ',
      tarih: '2026-10-10',
      olusturanKullanici: 'admin',
      olusturmaTarihi: '2026-10-10 08:00:00',
    );

    final p1 = PersonelTableData(
      id: 1,
      adSoyad: 'AHMET YILMAZ',
      rutbe: 'J.Ütğm.',
      birlik: '1. Komando Bölüğü',
      telefon: '05551112233',
      kayitTarihi: '2026-01-01',
      aktif: true,
      isDemo: false,
    );

    final p2 = PersonelTableData(
      id: 2,
      adSoyad: 'MEHMET DEMİR',
      rutbe: 'J.Asb.Kd.Bçvş.',
      birlik: '1. Komando Bölüğü',
      telefon: '05552223344',
      kayitTarihi: '2026-01-01',
      aktif: true,
      isDemo: false,
    );

    final p3 = PersonelTableData(
      id: 3,
      adSoyad: 'ALİ KAYA',
      rutbe: 'Uzm.J.',
      birlik: '1. Komando Bölüğü',
      telefon: '05553334455',
      kayitTarihi: '2026-01-01',
      aktif: true,
      isDemo: false,
    );

    final p4 = PersonelTableData(
      id: 4,
      adSoyad: 'HÜSEYİN ÇELİK',
      rutbe: 'J.Uzm.Çvş.',
      birlik: '1. Komando Bölüğü',
      telefon: '05554445566',
      kayitTarihi: '2026-01-01',
      aktif: true,
      isDemo: false,
    );

    final assignments = [
      FaaliyetPersonelAtamaTableData(
        id: 1,
        faaliyetId: 101,
        personelId: 1,
        gorevVeyaIzin: 'GÖREVLİ',
        durum: 'onaylandi',
        aciklama: 'TRANSİT 23 JAA 240',
      ),
      FaaliyetPersonelAtamaTableData(
        id: 2,
        faaliyetId: 101,
        personelId: 2,
        gorevVeyaIzin: 'GÖREVLİ',
        durum: 'onaylandi',
        aciklama: null,
      ),
      FaaliyetPersonelAtamaTableData(
        id: 3,
        faaliyetId: 101,
        personelId: 3,
        gorevVeyaIzin: 'GÖREVLİ',
        durum: 'onaylandi',
        aciklama: null,
      ),
      FaaliyetPersonelAtamaTableData(
        id: 4,
        faaliyetId: 101,
        personelId: 4,
        gorevVeyaIzin: 'GÖREVLİ',
        durum: 'onaylandi',
        aciklama: null,
      ),
    ];

    final personnelMap = {1: p1, 2: p2, 3: p3, 4: p4};

    test('faaliyeti doğru kuvvet, en kıdemli komutan ve saatlerle dönüştürür', () {
      final operation = TemgundrapActivityConverter.convert(
        activity: activity,
        assignments: assignments,
        personnelMap: personnelMap,
      );

      // Kuvvet testi: 1 Subay, 1 Astsubay, 1 Uzm.J, 1 Uzm.Çvş = Toplam 4
      expect(operation.strength.officer, equals(1));
      expect(operation.strength.nco, equals(1));
      expect(operation.strength.specialistGendarmerie, equals(1));
      expect(operation.strength.specialistSergeant, equals(1));
      expect(operation.totalStrength, equals(4));

      // Komutan: En kıdemli Üsteğmen (p1)
      expect(operation.commander.personnelId, equals(1));
      expect(operation.commander.name, equals('AHMET YILMAZ'));
      expect(operation.commander.rank, equals('J.Ütğm.'));
      expect(operation.commander.phone, equals('05551112233'));

      // Bölge: 'PALU İLÇE J.K.LIĞI' ile eşleşmeli
      expect(operation.operationArea, equals('PALU İLÇE J.K.LIĞI'));

      // Saatler: 09:00 - 17:00
      expect(operation.startAt.hour, equals(9));
      expect(operation.startAt.minute, equals(0));
      expect(operation.endAt.hour, equals(17));
      expect(operation.endAt.minute, equals(0));

      // Amaç: 'YOL EMNİYETİ'
      expect(operation.purpose, equals('YOL EMNİYETİ'));

      // Araç: TRANSİT 23 JAA 240
      expect(operation.vehicles, isNotEmpty);
      expect(operation.vehicles.first.model, equals('TRANSİT'));
      expect(operation.vehicles.first.plate, equals('23 JAA 240'));
    });

    test('saat ve araç belirtilmemişse varsayılan değerleri kullanır', () {
      final plainActivity = GunlukFaaliyetTableData(
        id: 102,
        faaliyetAdi: 'MERKEZ KONTROL NOKTASI',
        tarih: '2026-10-10',
        olusturanKullanici: 'admin',
        olusturmaTarihi: '2026-10-10 08:00:00',
      );

      final operation = TemgundrapActivityConverter.convert(
        activity: plainActivity,
        assignments: [assignments[1]], // sadece Mehmet Demir (Astsubay)
        personnelMap: personnelMap,
      );

      expect(operation.strength.nco, equals(1));
      expect(operation.strength.officer, equals(0));
      expect(operation.commander.name, equals('MEHMET DEMİR'));
      expect(operation.startAt.hour, equals(8));
      expect(operation.endAt.hour, equals(17));
      expect(operation.purpose, equals('KONTROL NOKTASI'));
      expect(operation.vehicles, isEmpty);
    });

    test('gece görevi (21:00 - 05:00) bitiş tarihini bir sonraki güne taşır', () {
      final nightActivity = GunlukFaaliyetTableData(
        id: 103,
        faaliyetAdi: 'KOVANCILAR İLÇE J.K.LIĞI 21:00 - 05:00 DEVRİYE HİZMETİ',
        tarih: '2026-10-10',
        olusturanKullanici: 'admin',
        olusturmaTarihi: '2026-10-10 08:00:00',
      );

      final operation = TemgundrapActivityConverter.convert(
        activity: nightActivity,
        assignments: [],
        personnelMap: personnelMap,
      );

      expect(operation.operationArea, equals('KOVANCILAR İLÇE J.K.LIĞI'));
      expect(operation.purpose, equals('DEVRİYE'));
      expect(operation.startAt.day, equals(10));
      expect(operation.startAt.hour, equals(21));
      expect(operation.endAt.day, equals(11)); // Ertesi gün
      expect(operation.endAt.hour, equals(5));
      expect(operation.totalStrength, equals(0));
      expect(operation.commander.name, isEmpty);
    });
  });
}
