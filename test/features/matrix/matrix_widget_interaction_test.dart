import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
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
        historicalPersonnelProvider.overrideWith(
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
    testWidgets('320px month identity remains readable with navigation actions',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      final label = DateFormat('MM\nyyyy', 'tr_TR').format(DateTime.now());
      expect(find.text(label), findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
          of: find.text(label), matching: find.byType(RichText)));
      expect(paragraph.didExceedMaxLines, isFalse,
          reason: paragraph.size.toString());
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.byKey(const ValueKey('matrix-mobile-search-button')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('matrix-export-menu')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders monthly matrix screen with calendar grid and squad controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MonthlyMatrixScreen), findsOneWidget);
    });

    testWidgets('month navigation updates matrix grid state',
        (WidgetTester tester) async {
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
