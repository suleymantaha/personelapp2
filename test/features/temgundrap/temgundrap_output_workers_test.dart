import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_excel_exporter.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_pdf_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final document = TemgundrapDocument(
    id: 'output',
    date: DateTime(2026, 10, 10),
    unitTitle: 'TEST BİRLİĞİ',
    approverName: 'TEST KOMUTAN',
    approverRank: 'TEST',
    approverDuty: 'TEST',
    operations: const [],
    isDraft: false,
    updatedAt: DateTime(2026, 10, 10),
  );

  test('background Excel encoding preserves title and signature', () async {
    final bytes = await TemgundrapExcelExporter.buildBytes(document);
    final sheet = Excel.decodeBytes(bytes)['TEMGÜNDRAP'];
    expect(sheet.cell(CellIndex.indexByString('A1')).value.toString(),
        TemgundrapPdfExporter.documentTitle(document));
    expect(sheet.cell(CellIndex.indexByString('I7')).value.toString(),
        'TEST KOMUTAN');
  });

  test('background PDF encoding embeds fonts and creates pages', () async {
    final bytes = await TemgundrapPdfExporter.buildBytes(document);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    final contents = String.fromCharCodes(bytes);
    expect(contents, contains('/FontFile2'));
    expect(contents.contains('/Type/Page'), isTrue);
  });

  testWidgets('PDF handoffs preserve earlier files and share anchor',
      (tester) async {
    await tester.runAsync(() async {
      final directory =
          await Directory.systemTemp.createTemp('temgun_pdf_test_');
      addTearDown(() => directory.delete(recursive: true));
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      const share = MethodChannel('dev.fluttercommunity.plus/share');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final arguments = <Map<Object?, Object?>>[];
      messenger.setMockMethodCallHandler(paths, (_) async => directory.path);
      messenger.setMockMethodCallHandler(share, (call) async {
        arguments.add(call.arguments as Map<Object?, Object?>);
        return 'dev.test.viewer';
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(paths, null);
        messenger.setMockMethodCallHandler(share, null);
      });
      const origin = Rect.fromLTWH(10, 20, 100, 200);
      await TemgundrapPdfExporter.shareDocument(document, null, origin);
      final firstPath = (arguments.first['paths'] as List).single as String;
      final original = await File(firstPath).readAsBytes();
      await TemgundrapPdfExporter.shareDocument(
        TemgundrapDocument.fromJson(
            {...document.toJson(), 'approverName': 'YENİ'}),
        null,
        origin,
      );
      final secondPath = (arguments.last['paths'] as List).single as String;
      expect(secondPath, isNot(firstPath));
      expect(await File(firstPath).readAsBytes(), original);
      expect(await File(secondPath).readAsBytes(), isNot(original));
      expect([
        arguments.first['originX'],
        arguments.first['originY'],
        arguments.first['originWidth'],
        arguments.first['originHeight'],
      ], [
        10.0,
        20.0,
        100.0,
        200.0
      ]);
    });
  });
}
