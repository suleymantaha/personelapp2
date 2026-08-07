import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/export_file_name_helper.dart';

void main() {
  group('formatExportFileName', () {
    test('preserves Turkish characters in title', () {
      final fileName = formatExportFileName(
        title: 'Günlük Tüm Faaliyetler Listesi',
        date: '2026-08-10',
        extension: 'pdf',
      );
      expect(fileName, equals('Günlük_Tüm_Faaliyetler_Listesi_2026-08-10.pdf'));
    });

    test('replaces invalid filesystem characters and extra spaces', () {
      final fileName = formatExportFileName(
        title: 'Nöbet / İzin  Listesi: Özel?',
        date: '10.08.2026',
        extension: 'xlsx',
      );
      expect(fileName, equals('Nöbet_İzin_Listesi_Özel_10.08.2026.xlsx'));
    });

    test('does not duplicate date if already present in title', () {
      final fileName = formatExportFileName(
        title: 'Faaliyet_Raporu_2026-08-10',
        date: '2026-08-10',
        extension: 'pdf',
      );
      expect(fileName, equals('Faaliyet_Raporu_2026-08-10.pdf'));
    });
  });
}
