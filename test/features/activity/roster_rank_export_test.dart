import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_preview_screen.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('rank option stays in this preview and fits a narrow phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: RosterOutputPreviewScreen(
          date: '2026-10-25',
          sources: const [],
          rows: const [],
          loadRows: () async => const [],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('roster-export-rank')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('export-option-temgundrap')), findsNothing);
    expect(find.byKey(const Key('roster-export')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rank Excel changes only exported order', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dir = Directory.systemTemp.createTempSync('roster_rank_export_');
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
      MilitaryRosterRow(
        sNu: 1,
        personelId: 1,
        birligi: 'Test',
        rutbe: 'J.Er',
        adSoyad: 'ER BİR',
        diger: '',
      ),
      MilitaryRosterRow(
        sNu: 2,
        personelId: 2,
        birligi: 'Test',
        rutbe: 'J.Yzb.',
        adSoyad: 'YÜZBAŞI İKİ',
        diger: '',
      ),
    ];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: RosterOutputPreviewScreen(
          date: '2026-10-25',
          sources: const [],
          rows: rows,
          loadRows: () async => rows,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    Future<List<String>> exportNames(String key) async {
      final before = shares.length;
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excel Olarak Aktar (.xlsx)'));
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && shares.length == before; i++) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(shares, hasLength(before + 1));
      final path = (shares.last['paths'] as List).single as String;
      final sheet =
          Excel.decodeBytes(File(path).readAsBytesSync())['İsim Listesi'];
      return sheet.rows
          .expand((r) => r)
          .map((cell) => cell?.value?.toString() ?? '')
          .where((value) => value == 'ER BİR' || value == 'YÜZBAŞI İKİ')
          .toList();
    }

    expect(await exportNames('roster-export-rank'), ['YÜZBAŞI İKİ', 'ER BİR']);
    expect(find.byKey(const Key('roster-export')), findsNothing);
    expect(rows.map((r) => r.sNu), [1, 2]);
  });
}
