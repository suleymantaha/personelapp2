import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/presentation/widgets/personnel_picker_sheet.dart';

void main() {
  const squads = [
    TimTableData(
      id: 2,
      timAdi: '7-B Timi',
      olusturmaTarihi: '2026-01-01',
    ),
    TimTableData(
      id: 3,
      timAdi: '8-B Timi',
      olusturmaTarihi: '2026-01-01',
    ),
    TimTableData(
      id: 1,
      timAdi: '6-B Timi',
      olusturmaTarihi: '2026-01-01',
    ),
  ];
  const personnel = [
    PersonelTableData(
      id: 1,
      adSoyad: 'İhsan DAĞLI',
      rutbe: 'J.Asb.Kd.Bçvş.',
      birlik: 'K.H',
      timId: 1,
      kayitTarihi: '2026-01-01',
    ),
    PersonelTableData(
      id: 2,
      adSoyad: 'Ahmet ÇALIŞKAN',
      rutbe: 'J.Uzm.Çvş.',
      birlik: 'K.H',
      timId: 2,
      kayitTarihi: '2026-01-01',
    ),
    PersonelTableData(
      id: 3,
      adSoyad: 'Ziya KAYA',
      rutbe: 'J.Uzm.Çvş.',
      birlik: 'K.H',
      timId: 1,
      kayitTarihi: '2026-01-01',
    ),
  ];

  testWidgets(
    'preferred team opens and Turkish-insensitive search opens matches',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PersonnelPickerSheet(
              personnel: personnel,
              squads: squads,
              preferredTimId: 1,
            ),
          ),
        ),
      );

      expect(find.text('6-B Timi — 2 kişi'), findsOneWidget);
      expect(find.text('7-B Timi — 1 kişi'), findsOneWidget);
      expect(find.text('8-B Timi — 0 kişi'), findsOneWidget);
      expect(find.text('J.Asb.Kd.Bçvş. İhsan DAĞLI'), findsOneWidget);
      expect(find.text('J.Uzm.Çvş. Ahmet ÇALIŞKAN'), findsNothing);
      expect(
        tester.getTopLeft(find.text('J.Asb.Kd.Bçvş. İhsan DAĞLI')).dy,
        lessThan(tester.getTopLeft(find.text('J.Uzm.Çvş. Ziya KAYA')).dy),
      );

      await tester.enterText(
        find.byKey(const Key('personnel-search-field')),
        'caliskan',
      );
      await tester.pump();

      expect(find.text('6-B Timi — 2 kişi'), findsNothing);
      expect(find.text('7-B Timi — 1 kişi'), findsOneWidget);
      expect(find.text('J.Uzm.Çvş. Ahmet ÇALIŞKAN'), findsOneWidget);
    },
  );

  testWidgets('shows guidance when no personnel matches', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PersonnelPickerSheet(personnel: personnel, squads: squads),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('personnel-search-field')),
      'bulunmayan kişi',
    );
    await tester.pump();

    expect(
      find.text('Aramanızla eşleşen personel bulunamadı.'),
      findsOneWidget,
    );
    expect(find.textContaining('Personel Yönetimi'), findsOneWidget);
  });

  testWidgets('disables personnel who already have a daily record',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PersonnelPickerSheet(
            personnel: personnel,
            squads: squads,
            preferredTimId: 1,
            disabledReasons: {1: 'Gece Devriyesi • NÖBETÇİ'},
          ),
        ),
      ),
    );

    expect(
      find.text('6-B Timi • Kayıtlı: Gece Devriyesi • NÖBETÇİ'),
      findsOneWidget,
    );
    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('J.Asb.Kd.Bçvş. İhsan DAĞLI'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.enabled, isFalse);
    expect(tile.onTap, isNull);
  });
}
