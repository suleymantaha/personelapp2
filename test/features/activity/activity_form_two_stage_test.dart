import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/presentation/activity_form_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  const personnel = [
    PersonelTableData(
      id: 1,
      adSoyad: 'Ahmet Yılmaz',
      rutbe: 'J.Bnb.',
      birlik: 'K.H',
      timId: 1,
      kayitTarihi: '2026-01-01',
    ),
    PersonelTableData(
      id: 2,
      adSoyad: 'Mehmet Demir',
      rutbe: 'J.Asb.',
      birlik: 'K.H',
      timId: 1,
      kayitTarihi: '2026-01-01',
    ),
    PersonelTableData(
      id: 3,
      adSoyad: 'Hasan Şahin',
      rutbe: 'J.Uzm.Çvş.',
      birlik: '2-B',
      timId: 2,
      kayitTarihi: '2026-01-01',
    ),
  ];

  Widget buildSubject({
    bool isAdmin = true,
    Widget? home,
  }) {
    return ProviderScope(
      overrides: [
        userSessionProvider.overrideWith(
          (ref) => UserSessionState(
            username: isAdmin ? 'admin' : 'komutan',
            role: isAdmin ? UserRole.admin : UserRole.teamCommander,
            timId: isAdmin ? null : 1,
          ),
        ),
        allPersonnelProvider.overrideWith((ref) => Stream.value(personnel)),
        allSquadsProvider.overrideWith(
          (ref) => Stream.value(const [
            TimTableData(id: 1, timAdi: 'K.H', olusturmaTarihi: ''),
            TimTableData(id: 2, timAdi: '2-B Timi', olusturmaTarihi: ''),
          ]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.militaryTheme,
        home: home ?? const ActivityFormScreen(),
      ),
    );
  }

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
  }

  testWidgets('starts with personnel-only first stage', (tester) async {
    await pumpAtSize(tester, const Size(412, 915));

    expect(find.byKey(const Key('personnel-selection-step')), findsOneWidget);
    expect(find.byKey(const Key('activity-details-step')), findsNothing);
    expect(find.byKey(const Key('personnel-search-field')), findsOneWidget);
    expect(find.byKey(const Key('activity-date-row')), findsNothing);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('continue-to-details-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('selects a squad and keeps selection while editing',
      (tester) async {
    await pumpAtSize(tester, const Size(412, 915));

    await tester.tap(find.byKey(const ValueKey('squad-select-K.H')));
    await tester.pumpAndSettle();
    expect(find.text('2 personel seçildi'), findsWidgets);
    expect(find.byKey(const ValueKey('selected-avatar-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('selected-avatar-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('continue-to-details-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activity-details-step')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('selected-squad-group-K.H')), findsOneWidget);
    expect(find.text('Ahmet Yılmaz'), findsNothing);
    expect(find.text('Mehmet Demir'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('selected-squad-group-K.H')));
    await tester.pumpAndSettle();
    expect(find.text('Ahmet Yılmaz'), findsOneWidget);
    expect(find.text('Mehmet Demir'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-personnel-selection')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personnel-selection-step')), findsOneWidget);
    expect(find.text('2 personel seçildi'), findsWidgets);
  });

  testWidgets('groups selected personnel under their own squads',
      (tester) async {
    await pumpAtSize(tester, const Size(412, 915));

    await tester.tap(find.byKey(const ValueKey('squad-select-K.H')));
    final secondSquad = find.byKey(const ValueKey('squad-select-2-B Timi'));
    await tester.ensureVisible(secondSquad);
    await tester.pumpAndSettle();
    await tester.tap(secondSquad);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-to-details-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('selected-squad-group-K.H')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selected-squad-group-2-B Timi')),
      findsOneWidget,
    );
    expect(find.text('Ahmet Yılmaz'), findsNothing);
    expect(find.text('Hasan Şahin'), findsNothing);
  });

  testWidgets('expanded squad uses compact personnel rows', (tester) async {
    await pumpAtSize(tester, const Size(412, 915));

    await tester.tap(find.byKey(const ValueKey('squad-select-K.H')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-to-details-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('selected-squad-group-K.H')));
    await tester.pumpAndSettle();

    final firstRow = find.byKey(const ValueKey('selected-personnel-1'));
    final secondRow = find.byKey(const ValueKey('selected-personnel-2'));
    expect(tester.getSize(firstRow).height, lessThanOrEqualTo(64));
    expect(tester.getSize(secondRow).height, lessThanOrEqualTo(64));
    expect(
      find.byKey(const ValueKey('selected-personnel-rank-1')),
      findsOneWidget,
    );
    expect(find.text('J.Bnb.'), findsOneWidget);
    final editButton = find.byKey(const ValueKey('edit-personnel-1'));
    expect(editButton, findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('selected-personnel-name-1')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('selected-personnel-rank-1')),
            )
            .dy,
      ),
    );
    expect(find.text('Ortak görev uygulanacak'), findsNothing);

    await tester.tap(editButton);
    await tester.pumpAndSettle();
    expect(find.text('Farklı görev seç'), findsOneWidget);
  });

  testWidgets('assigns one duty to every member of a squad', (tester) async {
    await pumpAtSize(tester, const Size(412, 915));

    await tester.tap(find.byKey(const ValueKey('squad-select-K.H')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-to-details-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('assign-squad-duty-K.H')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('squad-duty-K.H-HAZIR KITA')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('selected-squad-group-K.H')));
    await tester.pumpAndSettle();

    expect(find.textContaining('HAZIR KITA'), findsNWidgets(2));
  });

  testWidgets('custom activity can be cancelled and submitted safely',
      (tester) async {
    await pumpAtSize(tester, const Size(412, 915));
    await tester.tap(find.byKey(const ValueKey('squad-select-K.H')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-to-details-button')));
    await tester.pumpAndSettle();

    Future<void> openCustomActivityDialog() async {
      await tester.tap(find.byKey(const Key('activity-name-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diğer'));
      await tester.pumpAndSettle();
    }

    await openCustomActivityDialog();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Faaliyet seçin'), findsOneWidget);

    await openCustomActivityDialog();
    await tester.enterText(
      find.byKey(const Key('custom-activity-name-field')),
      'Eğitim Faaliyeti',
    );
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Eğitim Faaliyeti'), findsOneWidget);
  });

  testWidgets('personnel note dialog can be cancelled safely', (tester) async {
    await pumpAtSize(tester, const Size(412, 915));
    await tester.tap(find.byKey(const ValueKey('squad-select-K.H')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-to-details-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('selected-squad-group-K.H')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-personnel-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not ekle veya düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('personnel-note-1')),
      'Geçici not',
    );
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('personnel-note-1')), findsNothing);
  });

  testWidgets('two-stage layout does not overflow supported widths',
      (tester) async {
    for (final size in const [
      Size(320, 568),
      Size(600, 960),
      Size(1024, 768),
      Size(1280, 800),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'viewport: $size');

      final squadSelector = find.byKey(const ValueKey('squad-select-K.H'));
      await tester.ensureVisible(squadSelector);
      await tester.pumpAndSettle();
      await tester.tap(squadSelector);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continue-to-details-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('activity-details-step')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'details viewport: $size');
      await tester.pumpWidget(const SizedBox.shrink());
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('commander sees approval-specific final action', (tester) async {
    await tester.pumpWidget(buildSubject(isAdmin: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('personnel-select-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-to-details-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Önizle ve Onaya Gönder'), findsOneWidget);
    expect(find.byTooltip('Toplu metin yapıştır'), findsNothing);
  });

  testWidgets('warns before leaving a dirty personnel selection',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('open-activity-form'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ActivityFormScreen(),
                  ),
                ),
                child: const Text('Faaliyet aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-activity-form')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('squad-select-K.H')));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Değişiklikler silinsin mi?'), findsOneWidget);

    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personnel-selection-step')), findsOneWidget);
  });
}
