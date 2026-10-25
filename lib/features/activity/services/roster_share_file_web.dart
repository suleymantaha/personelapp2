import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'roster_share_mime.dart';

int _sequence = 0;

/// In-memory bytes avoid native filesystem APIs and retain each handoff.
Future<XFile> createRosterShareFile(String fileName, List<int> bytes) async {
  final token = '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
  final dot = fileName.lastIndexOf('.');
  final name = dot < 0
      ? '${fileName}_$token'
      : '${fileName.substring(0, dot)}_$token${fileName.substring(dot)}';
  return XFile.fromData(Uint8List.fromList(bytes),
      name: name, mimeType: rosterMimeType(fileName));
}

Future<XFile> saveRosterToDevice(String fileName, List<int> bytes) async {
  final file = XFile.fromData(Uint8List.fromList(bytes),
      name: fileName, mimeType: rosterMimeType(fileName));
  await file.saveTo(fileName);
  return file;
}
