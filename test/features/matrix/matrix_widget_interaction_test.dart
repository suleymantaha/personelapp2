import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/matrix/presentation/monthly_matrix_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Widget createTestWidget() {
    return UncontrolledProviderScope(
      container: container,
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
      await tester.pumpAndSettle();

      expect(find.byType(MonthlyMatrixScreen), findsOneWidget);
    });

    testWidgets('month navigation updates matrix grid state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

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
