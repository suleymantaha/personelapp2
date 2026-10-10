// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final dir = Directory('lib');
  final turkishRegex = RegExp(r'[çÇğĞıİöÖşŞüÜ]');

  final filesWithTurkish = <String, List<String>>{};

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.contains('.dart_tool') &&
        !entity.path.contains('generated')) {
      final lines = entity.readAsLinesSync();
      final matches = <String>[];
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();
        if (trimmed.startsWith('//') ||
            trimmed.startsWith('/*') ||
            trimmed.startsWith('*')) {
          continue;
        }
        if (turkishRegex.hasMatch(line)) {
          if (line.contains("'") || line.contains('"')) {
            matches.add('Line ${i + 1}: $trimmed');
          }
        }
      }
      if (matches.isNotEmpty) {
        filesWithTurkish[entity.path] = matches;
      }
    }
  }

  print('=== TOTAL FILES WITH HARDCODED TURKISH STRINGS: ${filesWithTurkish.length} ===\n');
  
  // Sort by count descending
  final sortedEntries = filesWithTurkish.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  for (final entry in sortedEntries) {
    print('${entry.key} -> ${entry.value.length} satır');
  }

  // Also write full details to a report file
  final reportFile = File('tool/hardcoded_report.txt');
  final buffer = StringBuffer();
  for (final entry in sortedEntries) {
    buffer.writeln('\n========================================');
    buffer.writeln('${entry.key} (${entry.value.length} items)');
    buffer.writeln('========================================');
    for (final match in entry.value) {
      buffer.writeln(match);
    }
  }
  reportFile.writeAsStringSync(buffer.toString());
  print('\nDetaylı rapor tool/hardcoded_report.txt dosyasına yazıldı.');
}
