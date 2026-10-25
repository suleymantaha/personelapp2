import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'roster_share_mime.dart';
import 'package:path_provider/path_provider.dart';

/// Keep each handoff immutable, including the basename copied by share_plus.
Future<XFile> createRosterShareFile(String fileName, List<int> bytes) async {
  final root = await getTemporaryDirectory();
  final directory = await root.createTemp('roster_export_');
  final token = directory.uri.pathSegments.where((s) => s.isNotEmpty).last;
  final dot = fileName.lastIndexOf('.');
  final uniqueName = dot < 0
      ? '${fileName}_$token'
      : '${fileName.substring(0, dot)}_$token${fileName.substring(dot)}';
  // Do not delete on share completion: viewers may still be reading the file.
  final file = await File('${directory.path}/$uniqueName')
      .writeAsBytes(bytes, flush: true);
  return XFile(file.path, mimeType: rosterMimeType(fileName));
}

Future<XFile> saveRosterToDevice(String fileName, List<int> bytes) async {
  Directory targetDir;
  try {
    if (Platform.isAndroid) {
      targetDir = Directory('/storage/emulated/0/Download');
      if (!targetDir.existsSync()) {
        targetDir = await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final userHome =
          Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (userHome != null) {
        targetDir = Directory('$userHome/Downloads');
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }
    } else {
      targetDir = await getApplicationDocumentsDirectory();
    }
  } catch (_) {
    targetDir = await getApplicationDocumentsDirectory();
  }

  final file = File('${targetDir.path}/$fileName');
  await file.writeAsBytes(bytes);
  return XFile(file.path, mimeType: rosterMimeType(fileName));
}
