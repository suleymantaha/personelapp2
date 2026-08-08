import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/personnel/presentation/widgets/personnel_form_dialog.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/backup_restore_dialog.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/bulk_personnel_import_dialog.dart';

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
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('Personnel Dialogs & Form Buttons Widget Tests', () {
    testWidgets('renders PersonnelFormDialog inputs and action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const PersonnelFormDialog()));
      await tester.pumpAndSettle();

      expect(find.byType(PersonnelFormDialog), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('renders BackupRestoreDialog buttons and tab controls', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(BackupRestoreDialog(database: db)));
      await tester.pumpAndSettle();

      expect(find.byType(BackupRestoreDialog), findsOneWidget);
    });

    testWidgets('renders BulkPersonnelImportDialog input area and parse button', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const BulkPersonnelImportDialog()));
      await tester.pumpAndSettle();

      expect(find.byType(BulkPersonnelImportDialog), findsOneWidget);
    });
  });
}
