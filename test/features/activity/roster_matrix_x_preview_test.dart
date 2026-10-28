import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_preview_screen.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';
import 'package:shared_preferences/shared_preferences.dart';

MilitaryRosterRow row(int id, String name, String rank) => MilitaryRosterRow(
      sNu: id,
      personelId: id,
      birligi: 'Test',
      rutbe: rank,
      adSoyad: name,
      diger: '',
    );

Map<int, MatrixDayCell> xDays(int count) => {
      for (var day = 1; day <= count; day++)
        day: const MatrixDayCell(
          displayCode: 'X',
          entries: [],
          hasConflict: false,
        ),
    };

void main() {
  testWidgets('rule preview uses the selected output day, not the whole month',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final rows = [row(1, 'PERSONEL', 'J.Er')];
    final matrix = {
      1: {
        ...xDays(19),
        25: xDays(1)[1]!,
        26: xDays(1)[1]!,
      },
    };
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: RosterOutputPreviewScreen(
          date: '2026-10-25',
          sources: const [],
          rows: rows,
          loadRows: () async => rows,
          loadMatrix: () async => matrix,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Aylık matris · 1–25 Ekim 2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('roster-matrix-rule-preview')));
    await tester.pumpAndSettle();
    expect(find.text('1 kişi çıktıda'), findsOneWidget);
    expect(find.text('0 kişi hariç'), findsOneWidget);
    expect(find.byKey(const Key('roster-rule-excluded-toggle')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('roster-preview-people-toggle')),
      150,
    );
    await tester.tap(find.byKey(const Key('roster-preview-people-toggle')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('roster-person-1')),
      150,
    );
    expect(find.byKey(const Key('roster-person-1')), findsOneWidget);
  });

  testWidgets('rule preview removes 21 X and exports remaining in rank order',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dir = Directory.systemTemp.createTempSync('roster_rule_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    messenger.setMockMethodCallHandler(paths, (_) async => dir.path);
    final shares = <Map<dynamic, dynamic>>[];
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      shares.add(call.arguments as Map<dynamic, dynamic>);
      return 'test.viewer';
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(paths, null);
      messenger.setMockMethodCallHandler(shareChannel, null);
    });

    final rows = [
      row(1, 'ER YİRMİ', 'J.Er'),
      row(2, 'ER YİRMİ BİR', 'J.Er'),
      row(3, 'YÜZBAŞI', 'J.Yzb.'),
    ];
    final matrix = {1: xDays(20), 2: xDays(21), 3: xDays(1)};
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: RosterOutputPreviewScreen(
          date: '2026-10-28',
          sources: const [],
          rows: rows,
          loadRows: () async => rows,
          loadMatrix: () async => matrix,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Personel listesi · 3'), findsOneWidget);
    expect(find.textContaining('ER YİRMİ BİR'), findsNothing);

    await tester.tap(find.byKey(const Key('roster-matrix-rule-preview')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('roster-preview-people-toggle')),
      150,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roster-preview-people-toggle')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('roster-person-3')),
      200,
    );
    expect(find.textContaining('ER YİRMİ BİR'), findsNothing);
    expect(find.textContaining('YÜZBAŞI'), findsOneWidget);
    expect(find.textContaining('ER YİRMİ'), findsOneWidget);
    expect(find.byKey(const Key('roster-rule-export')), findsOneWidget);
    final excludedCount = find.byKey(const Key('roster-rule-excluded-count'));
    await tester.scrollUntilVisible(excludedCount, -140);
    expect(find.text('ER YİRMİ BİR'), findsNothing);
    await tester.tap(excludedCount);
    await tester.pumpAndSettle();
    expect(find.text('ER YİRMİ BİR'), findsOneWidget);
    expect(find.text('21 gün X'), findsOneWidget);
    expect(matrix[2], hasLength(21));
    await tester.tap(find.byKey(const Key('roster-rule-sheet-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('roster-rule-export')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('export-option-temgundrap')), findsNothing);
    await tester.tap(find.text('Excel Olarak Aktar (.xlsx)'));
    await tester.runAsync(() async {
      for (var i = 0; i < 100 && shares.isEmpty; i++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    expect(shares, hasLength(1));
    final path = (shares.single['paths'] as List).single as String;
    final names =
        Excel.decodeBytes(File(path).readAsBytesSync())['İsim Listesi']
            .rows
            .expand((r) => r)
            .map((cell) => cell?.value?.toString() ?? '')
            .where((name) => name == 'YÜZBAŞI' || name.startsWith('ER YİRMİ'))
            .toList();
    expect(names, ['YÜZBAŞI', 'ER YİRMİ']);
    expect(rows.map((r) => r.personelId), [1, 2, 3]);
  });

  testWidgets('matrix changes after preview block the rule export',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final rows = [row(1, 'PERSONEL', 'J.Er')];
    var loadCount = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: RosterOutputPreviewScreen(
          date: '2026-10-28',
          sources: const [],
          rows: rows,
          loadRows: () async => rows,
          loadMatrix: () async => {1: xDays(++loadCount == 1 ? 20 : 21)},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roster-matrix-rule-preview')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roster-rule-export')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excel Olarak Aktar (.xlsx)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('yeniden'), findsWidgets);
  });

  testWidgets('all excluded leaves rule export disabled on a narrow phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rows = [row(1, 'PERSONEL', 'J.Er')];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: RosterOutputPreviewScreen(
          date: '2026-10-28',
          sources: const [],
          rows: rows,
          loadRows: () async => rows,
          loadMatrix: () async => {1: xDays(21)},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roster-matrix-rule-preview')));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('roster-rule-export')),
    );
    expect(button.onPressed, isNull);
    final excludedCount = find.byKey(const Key('roster-rule-excluded-count'));
    await tester.scrollUntilVisible(excludedCount, 100);
    await tester.pumpAndSettle();
    await tester.tap(excludedCount);
    await tester.pumpAndSettle();
    expect(find.text('PERSONEL'), findsOneWidget);
    expect(find.text('21 gün X'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
