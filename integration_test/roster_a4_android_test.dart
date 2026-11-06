import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/widgets/roster_format_actions.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';

import '../test/support/roster_a4_fixture.dart';

const _date = '2026-11-03';
const _archive = 'GÜNLÜK TÜM FAALİYETLER';
const _signers = [
  RosterSigner('TANZİM EDEN', 'ÖRNEK TANZİM', 'J.Asb.', 'Örnek görev'),
  RosterSigner('TASDİK EDEN', 'ÖRNEK TASDİK', 'J.Yb.', 'Örnek görev'),
];

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  const share = MethodChannel('dev.fluttercommunity.plus/share');
  const print = MethodChannel('nizam/roster_print');

  testWidgets('Android roster options produce independent A4 artifacts',
      (tester) async {
    final ordinary = a4ReferenceRows(133);
    final signed = a4ReferenceRows(105);
    final shared = <Uint8List>[];
    final printed = <(int, Uint8List)>[];
    final messenger = tester.binding.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(share, (call) async {
      expect(call.method, 'share');
      final args = call.arguments as Map;
      final path = (args['paths'] as List).single as String;
      shared.add(File(path).readAsBytesSync());
      return 'qa-capture';
    });
    messenger.setMockMethodCallHandler(print, (call) async {
      expect(call.method, 'printPdf');
      final args = call.arguments as Map;
      printed.add((args['pageCount'] as int, args['bytes'] as Uint8List));
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(share, null);
      messenger.setMockMethodCallHandler(print, null);
    });

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return Column(
              children: [
                TextButton(
                  key: const Key('ordinary'),
                  onPressed: () => showRosterFormatActions(
                    context,
                    name: _archive,
                    date: _date,
                    subtitle: '133 personel',
                    loadRows: () async => ordinary,
                  ),
                  child: const Text(_archive),
                ),
                TextButton(
                  key: const Key('signed'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RosterOutputPreviewScreen(
                        date: '2026-11-23',
                        sources: const [],
                        rows: signed,
                        loadRows: () async => signed,
                        loadMatrix: () async => {
                          1: {
                            for (var day = 1; day <= 21; day++)
                              day: const MatrixDayCell(
                                displayCode: 'X',
                                entries: [],
                                hasConflict: false,
                              ),
                          },
                        },
                        loadSigners: () async => _signers,
                      ),
                    ),
                  ),
                  child: const Text('İmzalı liste'),
                ),
              ],
            );
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const Key('ordinary')));
    await _tap(tester, find.byKey(const Key('export-option-excel')));
    await _wait(tester, () => shared.length == 1);
    _checkWorkbook(shared[0], 133, signed: false);

    await _tap(tester, find.byKey(const Key('ordinary')));
    await _tap(tester, find.byKey(const Key('export-option-pdf')));
    await _tap(tester, find.textContaining('Stil 1:'));
    await _wait(tester, () => shared.length == 2);
    expect(ascii.decode(shared[1].take(4).toList()), '%PDF');

    await _tap(tester, find.byKey(const Key('signed')));
    await _tap(tester, find.byKey(const Key('roster-export-rank')));
    await _tap(tester, find.byKey(const Key('export-option-excel')));
    await _wait(tester, () => shared.length == 3);
    _checkWorkbook(shared[2], 105, signed: true);

    for (var style = 1; style <= 3; style++) {
      await _tap(tester, find.byKey(const Key('roster-export-rank')));
      await _tap(tester, find.byKey(const Key('export-option-print')));
      await _tap(tester, find.textContaining('Stil $style:'));
      await _wait(tester, () => printed.length == style);
      final (pages, bytes) = printed.last;
      expect(pages, inInclusiveRange(2, 3));
      expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    }
    await _tap(tester, find.byKey(const Key('roster-matrix-rule-preview')));
    await _tap(tester, find.byKey(const Key('roster-rule-export')));
    await _tap(tester, find.byKey(const Key('export-option-excel')));
    await _wait(tester, () => shared.length == 4);
    _checkWorkbook(shared[3], 104, signed: true);
    expect(tester.takeException(), isNull);

    binding.reportData = {
      'archive-133.xlsx': base64Encode(shared[0]),
      'archive-133.pdf': base64Encode(shared[1]),
      'signed-105.xlsx': base64Encode(shared[2]),
      'rule-104.xlsx': base64Encode(shared[3]),
      for (final (index, result) in printed.indexed)
        'signed-105-style-${index + 1}.pdf': base64Encode(result.$2),
    };
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('roster-a4-signed-preview');

    messenger.setMockMethodCallHandler(print, null);
    await _tap(tester, find.byKey(const Key('roster-export-rank')));
    await _tap(tester, find.byKey(const Key('export-option-print')));
    await _tap(tester, find.textContaining('Stil 1:'));
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _wait(WidgetTester tester, bool Function() ready) async {
  for (var attempt = 0; attempt < 120 && !ready(); attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(ready(), isTrue);
  await tester.pumpAndSettle();
}

void _checkWorkbook(Uint8List bytes, int count, {required bool signed}) {
  final sheet = Excel.decodeBytes(bytes).tables.values.single;
  final values = sheet.rows
      .expand((row) => row)
      .whereType<Data>()
      .map((cell) => cell.value.toString())
      .toList();
  expect(
      values
          .where((text) =>
              text.startsWith('ÖRNEK ') &&
              RegExp(r'^ÖRNEK \d{3} ').hasMatch(text))
          .length,
      count);
  expect(values.contains('ÖRNEK TANZİM'), signed);
  expect(values.contains('ÖRNEK TASDİK'), signed);
}
