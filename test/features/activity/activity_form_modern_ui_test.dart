import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/presentation/activity_form_screen.dart';

void main() {
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

  testWidgets('modern form stays usable on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Faaliyet Çizelgesi'), findsOneWidget);
    expect(find.byTooltip('Toplu metin yapıştır'), findsOneWidget);
    expect(find.byKey(const Key('activity-date-row')), findsOneWidget);
    expect(find.byKey(const Key('save-activity-button')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Heybet'));
    await tester.pump();
    await tester.tap(find.text('Heybet'));
    await tester.pump();
    final nameField = tester.widget<TextField>(
      find.byKey(const Key('activity-name-field')),
    );
    expect(nameField.controller?.text, 'Heybet');
  });

  testWidgets('personnel search filters visible units', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('K.H'), findsOneWidget);
    expect(find.text('2-B Timi'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('personnel-search-field')),
      'Mehmet',
    );
    await tester.pump();

    expect(find.text('K.H'), findsNothing);
    expect(find.text('2-B Timi'), findsOneWidget);
  });
}
