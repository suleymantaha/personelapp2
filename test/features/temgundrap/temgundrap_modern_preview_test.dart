import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_preview_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  final document = TemgundrapDocument(
    id: 'doc',
    date: DateTime(2026, 8, 7),
    unitTitle: 'KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI',
    approverName: '',
    approverRank: '',
    approverDuty: '',
    isDraft: true,
    updatedAt: DateTime(2026),
    operations: [
      TemgundrapOperation(
        id: 'op',
        issuingUnit: 'ELAZIĞ İL J.K.LIĞI',
        operationArea: 'ELAZIĞ İL MERKEZ',
        commander: const CommanderSnapshot(
          personnelId: 1,
          name: 'Mehmet CEYLAN',
          rank: 'J.Ütğm.',
          phone: '545 864 19 02',
        ),
        strength: const TemgundrapStrength(officer: 1, nco: 2),
        vehicles: const [],
        startAt: DateTime(2026, 8, 6, 18, 18),
        endAt: DateTime(2026, 8, 6, 19, 18),
        purpose: 'GÖREVLENDİRME',
        description: 'Açıklama',
      ),
    ],
  );

  testWidgets('modern önizleme kartı ve ortak çıktı eylemlerini gösterir', (
    tester,
  ) async {
    var printCount = 0;
    var shareCount = 0;
    var excelCount = 0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: TemgundrapPreviewScreen(
          document: document,
          onPrint: () async => printCount++,
          onShare: () async => shareCount++,
          onExcel: () async => excelCount++,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('preview-operation-0')), findsOneWidget);
    expect(find.text('ELAZIĞ İL MERKEZ'), findsOneWidget);
    expect(find.text('YAZDIR'), findsOneWidget);
    expect(find.text('PDF PAYLAŞ'), findsOneWidget);
    expect(find.text('EXCEL'), findsOneWidget);
    await tester.tap(find.byKey(const Key('preview-print')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('preview-share')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('preview-excel')));
    await tester.pump();

    expect(printCount, 1);
    expect(shareCount, 1);
    expect(excelCount, 1);
    expect(tester.takeException(), isNull);
  });
}
