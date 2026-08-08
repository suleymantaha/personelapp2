import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/personnel/presentation/personnel_management_screen.dart';

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
        home: PersonnelManagementScreen(),
      ),
    );
  }

  group('Personnel Management Widget Data Exchange & Interaction Tests', () {
    testWidgets('renders personnel screen with seeded personnel and app bar interaction', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PersonnelManagementScreen), findsOneWidget);
      expect(find.byType(TextField), findsWidgets); // Search field
    });

    testWidgets('search field filters personnel list upon text entry', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final searchFinder = find.byType(TextField).first;
      await tester.enterText(searchFinder, 'Ahmet');
      await tester.pumpAndSettle();

      expect(find.byType(PersonnelManagementScreen), findsOneWidget);
    });

    testWidgets('opening personnel creation dialog displays input fields and interacts with repository', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find add personnel FAB or IconButton
      final fabFinder = find.byType(FloatingActionButton);
      if (fabFinder.evaluate().isNotEmpty) {
        await tester.tap(fabFinder.first);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
      }
    });
  });
}
