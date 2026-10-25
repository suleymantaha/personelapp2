@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/services/roster_share_file.dart';
import 'package:personelapp2/core/services/backup_file_gateway.dart';

@JS('document.querySelector')
external JSObject? _querySelector(JSString selector);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('browser roster attachments preserve bytes and unique named identities',
      () async {
    final dynamic first =
        await createRosterShareFile('Görev.xlsx', [1, 2, 255]);
    final dynamic second = await createRosterShareFile('Görev.xlsx', [3, 4]);
    expect(await first.readAsBytes(), [1, 2, 255]);
    expect(await second.readAsBytes(), [3, 4]);
    expect(first.name, startsWith('Görev_'));
    expect(first.name, endsWith('.xlsx'));
    expect(first.name, isNot(second.name));
    expect(first.path, isNot(second.path));
    expect(first.mimeType,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  });
  test('browser backup initiates download without native save dialog',
      () async {
    expect(await DeviceBackupFileGateway().saveBackup('{"sentetik":"şğ"}'),
        isTrue);
    final anchor = _querySelector('#__x_file_dom_element a'.toJS)!;
    final name = anchor.getProperty<JSString>('download'.toJS).toDart;
    final href = anchor.getProperty<JSString>('href'.toJS).toDart;
    expect(name, startsWith('Nizam_Yedek_'));
    expect(name, endsWith('.nizam'));
    expect(await XFile(href).readAsString(), '{"sentetik":"şğ"}');
  });
}
