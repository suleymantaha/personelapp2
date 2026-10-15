import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';
import 'package:personelapp2/features/activity/services/roster_signature_store.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const edited = [
    RosterSigner('TANZİM EDEN', 'Örnek Tanzim', 'Rütbe A', 'Görev A'),
    RosterSigner('TASDİK EDEN', 'Örnek Tasdik', 'Rütbe B', 'Görev B'),
  ];
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a new store instance loads both saved signers', () async {
    await RosterSignatureStore().save(edited);
    final loaded = await RosterSignatureStore().load();
    expect(loaded.map((s) => s.name), ['Örnek Tanzim', 'Örnek Tasdik']);
    expect(loaded.map((s) => s.rank), ['Rütbe A', 'Rütbe B']);
    expect(loaded.map((s) => s.role), ['Görev A', 'Görev B']);
  });

  test('malformed stored data falls back without overwriting storage',
      () async {
    SharedPreferences.setMockInitialValues(
        {RosterSignatureStore.storageKey: '[{}]'});
    final loaded = await RosterSignatureStore().load();
    expect(loaded, hasLength(2));
    expect(loaded.first.name, 'İhsan DAĞLI');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(RosterSignatureStore.storageKey), '[{}]');
  });

  test('Excel contains the edited signatures instead of default names', () {
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Test',
      tarih: '2026-10-10',
      rows: [
        MilitaryRosterRow(
            sNu: 1,
            birligi: 'Test',
            rutbe: 'Test',
            adSoyad: 'Test Personel',
            diger: '')
      ],
      includeSignatures: true,
      signers: edited,
    );
    final book = Excel.decodeBytes(bytes);
    final values = book.tables.values
        .expand((sheet) => sheet.rows)
        .expand((row) => row)
        .map((cell) => cell?.value.toString())
        .toList();
    for (final value in [
      'Örnek Tanzim',
      'Örnek Tasdik',
      'Rütbe A',
      'Rütbe B',
      'Görev A',
      'Görev B'
    ]) {
      expect(values, contains(value));
    }
    expect(values, isNot(contains('İhsan DAĞLI')));
    expect(values, isNot(contains('Serdar YILDIZ')));
  });
}
