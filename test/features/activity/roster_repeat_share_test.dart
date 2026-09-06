import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Excel and PDF shares keep distinct attachment identities', () async {
    final dir = await Directory.systemTemp.createTemp('roster_test_');
    addTearDown(() => dir.delete(recursive: true));
    final calls = <Map<dynamic, dynamic>>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    const share = MethodChannel('dev.fluttercommunity.plus/share');
    messenger.setMockMethodCallHandler(paths, (_) async => dir.path);
    messenger.setMockMethodCallHandler(share, (call) async {
      calls.add(call.arguments as Map<dynamic, dynamic>);
      return 'dev.test.viewer';
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(paths, null);
      messenger.setMockMethodCallHandler(share, null);
    });
    await MilitaryRosterExporter.shareExcelRoster(
      faaliyetAdi: 'Test',
      tarih: '2026-09-06',
      rows: [],
    );
    await PdfRosterExporter.sharePdfRoster(
      faaliyetAdi: 'Test',
      tarih: '2026-09-06',
      rows: [],
    );
    await MilitaryRosterExporter.shareExcelRoster(
      faaliyetAdi: 'Test',
      tarih: '2026-09-06',
      rows: [],
    );
    expect(calls, hasLength(3));
    final first = (calls[0]['paths'] as List).single as String;
    final second = (calls[2]['paths'] as List).single as String;
    expect(first.split(Platform.pathSeparator).last,
        isNot(second.split(Platform.pathSeparator).last));
    expect(calls[0]['mimeTypes'],
        ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']);
    expect(calls[1]['mimeTypes'], ['application/pdf']);
    expect(calls[2]['mimeTypes'],
        ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']);
  });
}
