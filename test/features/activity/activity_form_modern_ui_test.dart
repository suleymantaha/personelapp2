import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
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
      birlik: '2-B',
      timId: 2,
      kayitTarihi: '2026-01-01',
    ),
  ];

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        userSessionProvider.overrideWith(
          (ref) => const UserSessionState(
            username: 'admin',
            role: UserRole.admin,
          ),
        ),
        allPersonnelProvider.overrideWith(
          (ref) => Stream.value(personnel),
        ),
        allSquadsProvider.overrideWith(
          (ref) => Stream.value(const [
            TimTableData(id: 1, timAdi: 'K.H', olusturmaTarihi: ''),
            TimTableData(id: 2, timAdi: '2-B Timi', olusturmaTarihi: ''),
          ]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.militaryTheme,
        home: const ActivityFormScreen(),
      ),
    );
  }

  Future<void> chooseActivity(WidgetTester tester, String activity) async {
    await tester.tap(find.byKey(const Key('activity-name-field')));
    await tester.pumpAndSettle();
    expect(find.text('Faaliyet Seç'), findsOneWidget);
    final activityFinder = find.text(activity).last;
    await tester.ensureVisible(activityFinder);
    await tester.pumpAndSettle();
    await tester.tap(activityFinder);
    await tester.pumpAndSettle();
  }

  Future<void> chooseCommonDuty(WidgetTester tester, String duty) async {
    await tester.tap(find.byKey(const Key('common-duty-field')));
    await tester.pumpAndSettle();
    final dutyFinder = find.byKey(ValueKey('common-duty-$duty'));
    await tester.ensureVisible(dutyFinder);
    await tester.pumpAndSettle();
    await tester.tap(dutyFinder);
    await tester.pumpAndSettle();
  }

  testWidgets('modern form stays usable on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Faaliyet Çizelgesi'), findsOneWidget);
    expect(find.byTooltip('Toplu metin yapıştır'), findsOneWidget);
    expect(find.byKey(const Key('personnel-selection-step')), findsOneWidget);
    expect(find.byKey(const Key('activity-date-row')), findsNothing);
    expect(find.byKey(const Key('continue-to-details-button')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('squad-select-K.H')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-to-details-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('activity-date-row')), findsOneWidget);
    expect(find.byKey(const Key('activity-name-field')), findsOneWidget);
    expect(find.byKey(const Key('common-duty-field')), findsOneWidget);
    expect(find.byKey(const Key('save-activity-button')), findsOneWidget);

    await chooseActivity(tester, 'Heybet');
    await chooseCommonDuty(tester, 'HEYBET');
    expect(find.text('Heybet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('personnel search filters visible units', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('K.H'), findsOneWidget);
    expect(find.text('2-B Timi'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('personnel-search-field')),
      'Mehmet',
    );
    await tester.pumpAndSettle();

    expect(find.text('K.H'), findsNothing);
    expect(find.text('2-B Timi'), findsOneWidget);
  });

  testWidgets('save opens preview before writing activity data',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: 'K.H',
            olusturmaTarihi: '2026-08-05',
          ),
        );
    await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: personnel.first.adSoyad,
            rutbe: personnel.first.rutbe,
            birlik: personnel.first.birlik,
            timId: const Value(1),
            kayitTarihi: personnel.first.kayitTarihi,
          ),
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          userSessionProvider.overrideWith(
            (ref) => const UserSessionState(
              username: 'admin',
              role: UserRole.admin,
            ),
          ),
          allPersonnelProvider.overrideWith(
            (ref) => Stream.value([personnel.first]),
          ),
          allSquadsProvider.overrideWith(
            (ref) => Stream.value(const [
              TimTableData(id: 1, timAdi: 'K.H', olusturmaTarihi: ''),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.militaryTheme,
          home: const ActivityFormScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('squad-select-K.H')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-to-details-button')));
    await tester.pumpAndSettle();
    await chooseActivity(tester, 'Heybet');
    await chooseCommonDuty(tester, 'HEYBET');

    await tester.tap(find.byKey(const Key('save-activity-button')));
    await tester.pumpAndSettle();

    expect(find.text('Görevlendirme Önizlemesi'), findsOneWidget);
    expect(
      await database.select(database.gunlukFaaliyetTable).get(),
      isEmpty,
    );
  });
}
