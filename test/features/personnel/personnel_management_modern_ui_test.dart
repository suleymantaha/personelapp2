import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/personnel/presentation/personnel_management_screen.dart';

void main() {
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
          (ref) => Stream.value(const [
            PersonelTableData(
              id: 1,
              adSoyad: 'Ahmet Yılmaz',
              rutbe: 'J.Bnb.',
              birlik: 'K.H',
              timId: 1,
              kayitTarihi: '2026-01-01',
            ),
          ]),
        ),
        allSquadsProvider.overrideWith(
          (ref) => Stream.value(const [
            TimTableData(id: 1, timAdi: 'K.H', olusturmaTarihi: ''),
          ]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.militaryTheme,
        home: const PersonnelManagementScreen(),
      ),
    );
  }

  testWidgets('personnel and squad UI stays compact on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Personel ve Timler'), findsOneWidget);
    expect(find.text('1 personel'), findsOneWidget);
    expect(find.text('Personel Ekle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new squad action opens the modern form', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byTooltip('Yönetim işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yeni tim'));
    await tester.pumpAndSettle();

    expect(find.text('Yeni Tim Oluştur'), findsOneWidget);
    expect(find.byKey(const Key('new-squad-name-field')), findsOneWidget);
    expect(find.byKey(const Key('create-squad-button')), findsOneWidget);
  });

  testWidgets('personnel add action offers text import and opens preview flow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.text('Personel Ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Tek Personel Ekle'), findsOneWidget);
    expect(find.text('Metinden Toplu Ekle'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-personnel-from-text-option')));
    await tester.pumpAndSettle();
    expect(find.text('Metinden Personel Ekle'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('bulk-personnel-text-field')),
      '1. J.Asb.Çvş. Ahmet YILMAZ',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('bulk-personnel-preview-button')),
    );
    await tester.tap(find.byKey(const Key('bulk-personnel-preview-button')));
    await tester.pump();

    expect(find.text('1 personel bulundu'), findsOneWidget);
    expect(find.text('Ahmet YILMAZ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
