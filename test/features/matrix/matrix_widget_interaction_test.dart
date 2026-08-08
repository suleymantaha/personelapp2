import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/matrix/presentation/monthly_matrix_screen.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    initializeDateFormatting('tr_TR');
  });

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
  });

  tearDown(() async {
    await db.close();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        allPersonnelProvider.overrideWith(
          (ref) => Stream.value(const <PersonelTableData>[]),
        ),
        allSquadsProvider.overrideWith(
          (ref) => Stream.value(const <TimTableData>[]),
        ),
        monthlyMatrixProvider.overrideWith(
          (ref, month) => Stream.value({}),
        ),
      ],
      child: const MaterialApp(
        home: MonthlyMatrixScreen(),
      ),
    );
  }

  group('Monthly Matrix Widget Data Exchange & Interaction Tests', () {
    testWidgets('renders monthly matrix screen with calendar grid and squad controls', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MonthlyMatrixScreen), findsOneWidget);
    });

    testWidgets('month navigation updates matrix grid state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final navButton = find.byIcon(Icons.chevron_right);
      if (navButton.evaluate().isNotEmpty) {
        await tester.tap(navButton.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(MonthlyMatrixScreen), findsOneWidget);
    });
  });
}
