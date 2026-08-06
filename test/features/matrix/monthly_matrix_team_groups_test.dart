import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/matrix/presentation/monthly_matrix_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  testWidgets('mobile matrix shows personnel under official team headers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const squads = [
      TimTableData(id: 1, timAdi: '7-B Timi', olusturmaTarihi: ''),
      TimTableData(id: 2, timAdi: 'K.H', olusturmaTarihi: ''),
    ];
    const personnel = [
      PersonelTableData(
        id: 1,
        adSoyad: 'Yedinci Tim Personeli',
        rutbe: 'J.Bnb.',
        birlik: '',
        timId: 1,
        kayitTarihi: '',
      ),
      PersonelTableData(
        id: 2,
        adSoyad: 'Karargah Personeli',
        rutbe: 'J.Ütğm.',
        birlik: '',
        timId: 2,
        kayitTarihi: '',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allPersonnelProvider.overrideWith((ref) => Stream.value(personnel)),
          allSquadsProvider.overrideWith((ref) => Stream.value(squads)),
          monthlyMatrixProvider.overrideWith((ref, month) => Stream.value({})),
        ],
        child: const MaterialApp(home: MonthlyMatrixScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('K.H'), findsOneWidget);
    expect(find.text('7-B Timi'), findsOneWidget);
    expect(find.text('1 Personel'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('K.H')).dy,
      lessThan(tester.getTopLeft(find.text('7-B Timi')).dy),
    );

    await tester.tap(find.text('K.H'));
    await tester.pumpAndSettle();
    expect(find.text('Karargah Personeli'), findsOneWidget);

    await tester.tap(find.text('Karargah Personeli'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('monthly-calendar-grid')), findsOneWidget);
    expect(find.text('Pzt'), findsOneWidget);
    expect(find.text('Paz'), findsOneWidget);
    expect(find.textContaining('Aylık çizelge ·'), findsOneWidget);
  });

  testWidgets('personnel search filters teams and can be cleared', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const squads = [
      TimTableData(id: 1, timAdi: '7-B Timi', olusturmaTarihi: ''),
      TimTableData(id: 2, timAdi: 'Karargah', olusturmaTarihi: ''),
    ];
    const personnel = [
      PersonelTableData(
        id: 1,
        adSoyad: 'Ayşe Çelik',
        rutbe: 'Astsubay',
        birlik: '',
        timId: 1,
        kayitTarihi: '',
      ),
      PersonelTableData(
        id: 2,
        adSoyad: 'Çağrı Öztürk',
        rutbe: 'Teğmen',
        birlik: '',
        timId: 2,
        kayitTarihi: '',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allPersonnelProvider.overrideWith((ref) => Stream.value(personnel)),
          allSquadsProvider.overrideWith((ref) => Stream.value(squads)),
          monthlyMatrixProvider.overrideWith((ref, month) => Stream.value({})),
        ],
        child: const MaterialApp(home: MonthlyMatrixScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aylık Matris'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('matrix-personnel-search')), findsOneWidget);
    expect(find.text('7-B Timi'), findsOneWidget);
    expect(find.text('Karargah'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('matrix-personnel-search')),
      'cagri ozturk',
    );
    await tester.pump();

    expect(find.text('7-B Timi'), findsNothing);
    expect(find.text('Karargah'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('matrix-personnel-search')),
      'bulunmayan',
    );
    await tester.pump();
    expect(
      find.text('Aramanızla eşleşen personel bulunamadı'),
      findsOneWidget,
    );

    await tester.tap(find.text('Aramayı temizle'));
    await tester.pump();
    expect(find.text('7-B Timi'), findsOneWidget);
    expect(find.text('Karargah'), findsOneWidget);
  });
}
