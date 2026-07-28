import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

void main() {
  ParsedActivityBlock block() => ParsedActivityBlock(
        rawTitle: '6/B Heybet Listesi',
        parsedTimName: '6/B',
        parsedActivityType: 'HEYBET',
        parsedDate: '2026-07-25',
        personnelList: const [],
      );

  BulkParseIssue issue(BulkParseIssueSeverity severity) => BulkParseIssue(
        lineNumber: 2,
        rawLine: '31.02.2026',
        code: 'invalid_date',
        message: 'Tarih geçerli değil.',
        severity: severity,
      );

  Future<void> pumpButton(
    WidgetTester tester, {
    required List<BulkParseIssue> issues,
    required VoidCallback onPressed,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BulkImportSaveButton(
            blocks: [block()],
            issues: issues,
            isSaving: false,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  testWidgets('critical parse issue disables save', (tester) async {
    var pressed = false;
    await pumpButton(
      tester,
      issues: [issue(BulkParseIssueSeverity.error)],
      onPressed: () => pressed = true,
    );

    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('bulk-import-save-button')),
    );
    expect(button.onPressed, isNull);
    await tester.tap(find.byKey(const Key('bulk-import-save-button')));
    expect(pressed, isFalse);
  });

  testWidgets('warning keeps save enabled', (tester) async {
    var pressed = false;
    await pumpButton(
      tester,
      issues: [issue(BulkParseIssueSeverity.warning)],
      onPressed: () => pressed = true,
    );

    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('bulk-import-save-button')),
    );
    expect(button.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('bulk-import-save-button')));
    expect(pressed, isTrue);
  });
}
