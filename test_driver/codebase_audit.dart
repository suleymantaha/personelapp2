import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name)) return false;
        final directory = Directory(
            Platform.environment['NIZAM_AUDIT_SCREENSHOTS'] ??
                'docs/audits/2026-11-01/screenshots');
        await directory.create(recursive: true);
        await File('${directory.path}/$name.png').writeAsBytes(bytes);
        return true;
      },
    );
