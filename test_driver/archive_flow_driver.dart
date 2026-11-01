import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(onScreenshot: (name, bytes, [args]) async {
    final directory = Directory('output/archive-flow-verification/device');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png').writeAsBytes(bytes);
    return bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50;
  });
}
