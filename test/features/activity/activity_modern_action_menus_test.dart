import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_personnel_duty_row.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_squad_expansion_tile.dart';

void main() {
  testWidgets('duty dropdown uses a constrained modern menu', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.militaryTheme,
        home: const Scaffold(
          body: ActivityPersonnelDutyRow(
            personnel: PersonelTableData(
              id: 1,
              adSoyad: 'Uzun İsimli Test Personeli',
              rutbe: 'J.Asb.Üçvş.',
              birlik: 'K.H',
              timId: 1,
              kayitTarihi: '2026-01-01',
            ),
            currentSelection: null,
            availableDuties: [
              'HEYBET KOMUTANI',
              'NÖBETÇİ',
              'İZİNLİ',
              'İSTİRAHATLİ',
              'RAPORLU',
              'SEVK',
              'DİĞER',
            ],
            adminOnlyDuties: ['HEYBET KOMUTANI'],
            onDutyChanged: _ignoreDuty,
          ),
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(dropdown.menuMaxHeight, 332.8);
    expect(dropdown.borderRadius, BorderRadius.circular(16));

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('HEYBET KOMUTANI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Widget buildSubject({
    required ValueChanged<String> onBatchAssign,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.militaryTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ActivitySquadExpansionTile(
            squadName: 'K.H',
            members: const [],
            assignments: const {},
            isAdmin: true,
            adminOnlyDuties: const [],
            generalDuties: const [
              'HAZIR KITA',
              'GÖREVLİ',
              'NÖBETÇİ',
              'İZİNLİ',
              'İSTİRAHATLİ',
              'RAPORLU',
              'SEVK',
              'DİĞER',
            ],
            onBatchAssign: onBatchAssign,
            onDutyChanged: (personId, duty) {},
          ),
        ),
      ),
    );
  }

  testWidgets('mobile batch duty panel is readable and returns selection', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? selectedDuty;

    await tester.pumpWidget(
      buildSubject(onBatchAssign: (duty) => selectedDuty = duty),
    );
    await tester.tap(find.byKey(const ValueKey('batch-duty-button-K.H')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Toplu görev ata'), findsOneWidget);
    expect(find.text('K.H timindeki tüm personele uygulanır'), findsOneWidget);
    expect(find.text('Tümüne "HAZIR KITA" Ata'), findsNothing);
    expect(find.text('HAZIR KITA'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('HAZIR KITA'));
    await tester.pumpAndSettle();
    expect(selectedDuty, 'HAZIR KITA');
  });

  testWidgets('clearing batch duties requires confirmation', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? selectedDuty;

    await tester.pumpWidget(
      buildSubject(onBatchAssign: (duty) => selectedDuty = duty),
    );
    await tester.tap(find.byKey(const ValueKey('batch-duty-button-K.H')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clear-batch-duty')));
    await tester.pumpAndSettle();

    expect(find.text('Görevler sıfırlansın mı?'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(selectedDuty, isNull);
    expect(find.text('Toplu görev ata'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear-batch-duty')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-clear-batch-duty')));
    await tester.pumpAndSettle();
    expect(selectedDuty, 'CLEAR');
  });

  testWidgets('wide layout uses a constrained dialog', (tester) async {
    tester.view
      ..physicalSize = const Size(900, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject(onBatchAssign: (_) {}));
    await tester.tap(find.byKey(const ValueKey('batch-duty-button-K.H')));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Toplu görev ata'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _ignoreDuty(String? duty) {}
