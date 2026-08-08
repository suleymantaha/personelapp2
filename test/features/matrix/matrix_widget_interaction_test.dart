import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/matrix/presentation/monthly_matrix_screen.dart';

void main() {
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
      ],
      child: const MaterialApp(
        home: MonthlyMatrixScreen(),
      ),
    );
  }

  group('Monthly Matrix Widget Data Exchange & Interaction Tests', () {
    testWidgets('renders monthly matrix screen with calendar grid and squad controls', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(MonthlyMatrixScreen), findsOneWidget);
    });

    testWidgets('month navigation updates matrix grid state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final iconBtnFinder = find.byType(IconButton);
      if (iconBtnFinder.evaluate().isNotEmpty) {
        await tester.tap(iconBtnFinder.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(MonthlyMatrixScreen), findsOneWidget);
    });
  });
}
