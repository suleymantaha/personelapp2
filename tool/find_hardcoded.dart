// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final dir = Directory('lib');
  final turkishCharRegex = RegExp(r'[çÇğĞıİöÖşŞüÜ]');
  final commonTurkishWordsRegex = RegExp(
    r'\b(kaydet|sil|iptal|vazgec|vazgeç|tamam|onayla|sec|seç|tarih|personel|tim|faaliyet|ekle|duzenle|düzenle|kapat|yukle|yükle|arsiv|arşiv|rapor|yazdir|yazdır|hata|uyari|uyarı|basarili|başarılı|bilgi|gorev|görev|komutan|ara|filtre|tumunu|tümünü|yeni|durum|ayarlar|cikis|çıkış|lütfen|gerekli|emin|misiniz|evet|hayir|hayır|kuvvet|zaman|alan|birlik)\b',
    caseSensitive: false,
  );

  final stringLiteralRegex = RegExp(r"""(?:'([^'\\]*(?:\\.[^'\\]*)*)'|"([^"\\]*(?:\\.[^"\\]*)*)")""");
  final interpolationRegex = RegExp(r'\$\{[^}]*\}|\$[a-zA-Z0-9_]+');

  final uiFilesWithHardcoded = <String, List<String>>{};
  final otherFilesWithHardcoded = <String, List<String>>{};

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.contains('.dart_tool') &&
        !entity.path.contains('generated') &&
        !entity.path.endsWith('.g.dart') &&
        !entity.path.endsWith('_previews.dart')) {
      final lines = entity.readAsLinesSync();
      final matches = <String>[];
      final isUiFile = entity.path.contains('presentation') ||
          entity.path.contains('widgets') ||
          entity.path.contains('dialogs') ||
          entity.path.contains('screens');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();

        // Yorum satırlarını atla
        if (trimmed.startsWith('//') ||
            trimmed.startsWith('/*') ||
            trimmed.startsWith('*')) {
          continue;
        }

        // Import/export/part direktiflerini atla
        if (trimmed.startsWith('import ') ||
            trimmed.startsWith('export ') ||
            trimmed.startsWith('part ')) {
          continue;
        }

        // Zaten localize edilmiş satırları atla
        if (trimmed.contains('context.l10n.') ||
            trimmed.contains('AppLocalizations.')) {
          continue;
        }

        // l10n fallback satırlarını atla (önceki veya aynı satırda l10n kontrolü)
        var isL10nFallback = trimmed.contains('l10n != null');
        if (!isL10nFallback) {
          for (var k = 1; k <= 8; k++) {
            if (i - k >= 0 && lines[i - k].contains('l10n != null')) {
              isL10nFallback = true;
              break;
            }
          }
        }
        if (isL10nFallback && (trimmed.startsWith(':') || trimmed.contains('l10n'))) {
          continue;
        }

        // Test veya Key tanımlarını atla
        if (trimmed.startsWith("Key('") ||
            trimmed.startsWith('Key("') ||
            trimmed.startsWith("ValueKey('") ||
            trimmed.startsWith('ValueKey("') ||
            trimmed.startsWith("const Key('") ||
            trimmed.startsWith('const Key("') ||
            trimmed.startsWith("key: const Key(") ||
            trimmed.startsWith("key: Key(") ||
            trimmed.startsWith("key: ValueKey(")) {
          continue;
        }

        // Asset yollarını atla
        if (trimmed.contains("'assets/") || trimmed.contains('"assets/')) {
          continue;
        }

        // @Preview annotasyonlarını atla
        if (trimmed.startsWith('@Preview(')) continue;

        // RegExp ve log/hata raporlama satırlarını atla
        if (trimmed.startsWith('RegExp(') ||
            trimmed.contains('RegExp(') ||
            trimmed.startsWith("r'") ||
            trimmed.startsWith('r"') ||
            trimmed.startsWith('_report') ||
            trimmed.contains('AppLogger.') ||
            trimmed.contains(".contains('") ||
            trimmed.contains('.contains("') ||
            (trimmed.contains('DateFormat') && trimmed.contains('tr_TR'))) {
          continue;
        }

        // String replace normalizasyonlarını atla
        if (trimmed.startsWith(".replaceAll('") || trimmed.startsWith('.replaceAll("')) continue;

        // DB sabitleri: durum: 'onaylandi' vb.
        if (trimmed.startsWith("durum: '") || trimmed.startsWith('durum: "')) continue;

        // String literal çıkarımı
        final rawMatches = stringLiteralRegex.allMatches(line);
        if (rawMatches.isEmpty) continue;

        var lineHasHardcoded = false;
        for (final m in rawMatches) {
          final literal = m.group(1) ?? m.group(2) ?? '';
          // Değişken interpolasyonlarını (${variable}, $variable) kaldır
          final literalWithoutVars = literal.replaceAll(interpolationRegex, '').trim();
          if (literalWithoutVars.isEmpty) continue;

          // Durum/kod sabitleri ('İZ', 'İST', 'RAP', 'X') atla
          if (literalWithoutVars == 'İZ' ||
              literalWithoutVars == 'İST' ||
              literalWithoutVars == 'RAP' ||
              literalWithoutVars == 'GÖREVLİ') {
            continue;
          }

          final hasTurkishChar = turkishCharRegex.hasMatch(literalWithoutVars);
          final hasTurkishWord = commonTurkishWordsRegex.hasMatch(literalWithoutVars);

          if (hasTurkishChar || hasTurkishWord) {
            lineHasHardcoded = true;
            break;
          }
        }

        if (lineHasHardcoded) {
          matches.add('Line ${i + 1}: $trimmed');
        }
      }

      if (matches.isNotEmpty) {
        if (isUiFile) {
          uiFilesWithHardcoded[entity.path] = matches;
        } else {
          otherFilesWithHardcoded[entity.path] = matches;
        }
      }
    }
  }

  print('=====================================================');
  print('📊 AKILLI L10N DENETİM RAPORU');
  print('=====================================================');
  print('🎯 Presentation / UI Dosyaları (Öncelikli): ${uiFilesWithHardcoded.length} dosya');
  print('📦 Diğer Katmanlar (Data/Domain/Utils): ${otherFilesWithHardcoded.length} dosya');
  print('-----------------------------------------------------\n');

  final sortedUi = uiFilesWithHardcoded.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  print('--- [UI / PRESENTATION DOSYALARI] ---');
  var totalUiLines = 0;
  for (final entry in sortedUi) {
    totalUiLines += entry.value.length;
    print('${entry.key} -> ${entry.value.length} satır');
  }
  print('\nToplam UI hardcoded satır sayısı: $totalUiLines\n');

  final reportFile = File('tool/hardcoded_report.txt');
  final buffer = StringBuffer();
  buffer.writeln('=====================================================');
  buffer.writeln('AKILLI L10N DENETİM RAPORU');
  buffer.writeln('Oluşturulma Tarihi: ${DateTime.now().toIso8601String()}');
  buffer.writeln('UI Dosyası Sayısı: ${uiFilesWithHardcoded.length} ($totalUiLines satır)');
  buffer.writeln('Diğer Dosya Sayısı: ${otherFilesWithHardcoded.length}');
  buffer.writeln('=====================================================\n');

  buffer.writeln('#####################################################');
  buffer.writeln('### 1. BÖLÜM: KULLANICI ARAYÜZÜ (UI / PRESENTATION) ###');
  buffer.writeln('#####################################################');
  for (final entry in sortedUi) {
    buffer.writeln('\n-----------------------------------------------------');
    buffer.writeln('${entry.key} (${entry.value.length} öğe)');
    buffer.writeln('-----------------------------------------------------');
    for (final match in entry.value) {
      buffer.writeln(match);
    }
  }

  buffer.writeln('\n\n#####################################################');
  buffer.writeln('### 2. BÖLÜM: VERİ / DOMAIN / UTILS (ARKA PLAN)    ###');
  buffer.writeln('#####################################################');
  final sortedOther = otherFilesWithHardcoded.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  for (final entry in sortedOther) {
    buffer.writeln('\n-----------------------------------------------------');
    buffer.writeln('${entry.key} (${entry.value.length} öğe)');
    buffer.writeln('-----------------------------------------------------');
    for (final match in entry.value) {
      buffer.writeln(match);
    }
  }

  reportFile.writeAsStringSync(buffer.toString());
  print('Detaylı kategorize rapor tool/hardcoded_report.txt dosyasına kaydedildi.');
}
