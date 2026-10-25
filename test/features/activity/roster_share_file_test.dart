import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/services/roster_share_file.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('native attachment preserves immutable bytes, extension and MIME type',
      () async {
    final root = await Directory.systemTemp.createTemp('nizam_export_test_');
    addTearDown(() => root.delete(recursive: true));
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => root.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final first = await createRosterShareFile('Görev.xlsx', [1, 2, 255]);
    final second = await createRosterShareFile('Görev.xlsx', [3, 4]);
    expect(first, isA<XFile>());
    expect(first.mimeType,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    expect(await first.readAsBytes(), [1, 2, 255]);
    expect(await second.readAsBytes(), [3, 4]);
    expect(first.path, isNot(second.path));
    expect(first.path, endsWith('.xlsx'));
  });
}
