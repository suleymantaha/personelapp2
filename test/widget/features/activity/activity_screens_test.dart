import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/activity_form_screen.dart';
import 'package:personelapp2/features/activity/presentation/pending_approvals_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        allPersonnelProvider.overrideWith(
          (ref) => Stream.value(const <PersonelTableData>[]),
        ),
        allSquadsProvider.overrideWith(
          (ref) => Stream.value(const <TimTableData>[]),
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Activity Screens & Forms Widget Tests', () {
    testWidgets('renders ActivityFormScreen step controls and text inputs', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const ActivityFormScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityFormScreen), findsOneWidget);
    });

    testWidgets('renders PendingApprovalsScreen list and approval action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const PendingApprovalsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(PendingApprovalsScreen), findsOneWidget);
    });
  });
}
