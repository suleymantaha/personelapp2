import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/presentation/widgets/personnel_picker_sheet.dart';

void main() {
  testWidgets('saved team and personnel order survives search and team filters',
      (tester) async {
    const squads = [
      TimTableData(id: 1, timAdi: 'K.H', sortOrder: 1, olusturmaTarihi: ''),
      TimTableData(
          id: 2, timAdi: '7-B Timi', sortOrder: 0, olusturmaTarihi: ''),
    ];
    const people = [
      PersonelTableData(
          id: 1,
          adSoyad: 'Ali Test',
          rutbe: 'J.Yb.',
          birlik: 'Test',
          timId: 2,
          sortOrder: 1,
          kayitTarihi: '',
          aktif: true,
          isDemo: false),
      PersonelTableData(
          id: 2,
          adSoyad: 'Ziya Test',
          rutbe: 'J.Uzm.Çvş.',
          birlik: 'Test',
          timId: 2,
          sortOrder: 0,
          kayitTarihi: '',
          aktif: true,
          isDemo: false),
      PersonelTableData(
          id: 3,
          adSoyad: 'Veli Test',
          rutbe: 'J.Asb.',
          birlik: 'Test',
          timId: 1,
          kayitTarihi: '',
          aktif: true,
          isDemo: false),
    ];
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PersonnelPickerSheet(
      personnel: people,
      squads: squads,
      preferredTimId: 2,
      onSelected: (_) {},
      disabledReasons: const {2: 'Test Faaliyeti'},
    ))));
    await tester.pumpAndSettle();
    final firstTeam = find.byKey(const Key('personnel-team-2'));
    final secondTeam = find.byKey(const Key('personnel-team-1'));
    expect(tester.getTopLeft(firstTeam).dy,
        lessThan(tester.getTopLeft(secondTeam).dy));
    final chips =
        tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    expect((chips[1].label as Text).data, '7-B Timi');
    void expectPersonnelOrder() {
      expect(
          tester.getTopLeft(find.byKey(const Key('personnel-option-2'))).dy,
          lessThan(tester
              .getTopLeft(find.byKey(const Key('personnel-option-1')))
              .dy));
    }

    expectPersonnelOrder();
    await tester.enterText(
        find.byKey(const Key('personnel-search-field')), 'Test');
    await tester.pumpAndSettle();
    expectPersonnelOrder();
    await tester.enterText(find.byKey(const Key('personnel-search-field')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '7-B Timi'));
    await tester.pumpAndSettle();
    expect(secondTeam, findsNothing);
    expectPersonnelOrder();
    expect(tester.takeException(), isNull);
  });
}
