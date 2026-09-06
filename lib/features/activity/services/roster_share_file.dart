import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Keep each handoff immutable, including the basename copied by share_plus.
Future<File> createRosterShareFile(String fileName, List<int> bytes) async {
  final root = await getTemporaryDirectory();
  final directory = await root.createTemp('roster_export_');
  final token = directory.uri.pathSegments.where((s) => s.isNotEmpty).last;
  final dot = fileName.lastIndexOf('.');
  final uniqueName = dot < 0
      ? '${fileName}_$token'
      : '${fileName.substring(0, dot)}_$token${fileName.substring(dot)}';
  // Do not delete on share completion: viewers may still be reading the file.
  return File('${directory.path}/$uniqueName').writeAsBytes(bytes, flush: true);
}
