import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:personelapp2/features/activity/domain/ocr/roster_ocr_name_extractor.dart';

class RosterImageImportResult {
  const RosterImageImportResult({
    required this.bulkImportText,
    required this.extractedNameCount,
    required this.sourceName,
    required this.rawOcrText,
  });

  final String bulkImportText;
  final int extractedNameCount;
  final String sourceName;
  final String rawOcrText;
}

class RosterImageImportService {
  static const MethodChannel _androidOcr = MethodChannel('nizam/ocr');
  static const XTypeGroup _imageType = XTypeGroup(
    label: 'Liste görseli',
    extensions: <String>['jpg', 'jpeg', 'png', 'heic', 'webp'],
    mimeTypes: <String>['image/jpeg', 'image/png', 'image/heic', 'image/webp'],
  );

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<RosterImageImportResult?> pickAndExtract() async {
    if (!isSupportedPlatform) {
      throw const RosterImageImportUnsupportedException();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return _pickAndExtractAndroid();
    }

    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[_imageType],
      confirmButtonText: 'Görseli seç',
    );
    if (file == null) return null;

    final localFile = await _copyToReadableCache(file);
    final rawText = await _recognizePluginText(localFile);
    final extraction = RosterOcrNameExtractor.extract(rawText);
    if (!extraction.hasNames) {
      throw const RosterImageImportNoNamesException();
    }
    return RosterImageImportResult(
      bulkImportText: extraction.toBulkImportText(),
      extractedNameCount: extraction.names.length,
      sourceName: file.name,
      rawOcrText: rawText,
    );
  }

  Future<RosterImageImportResult?> _pickAndExtractAndroid() async {
    final rawText = await _androidOcr.invokeMethod<String>(
      'pickAndRecognizeLatinText',
    );
    if (rawText == null) return null;
    final extraction = RosterOcrNameExtractor.extract(rawText);
    if (!extraction.hasNames) {
      throw const RosterImageImportNoNamesException();
    }
    return RosterImageImportResult(
      bulkImportText: extraction.toBulkImportText(),
      extractedNameCount: extraction.names.length,
      sourceName: 'Android görsel seçici',
      rawOcrText: rawText,
    );
  }

  Future<String> _recognizePluginText(File file) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = InputImage.fromFilePath(file.path);
      final recognized = await recognizer.processImage(image);
      return recognized.text;
    } finally {
      await recognizer.close();
    }
  }

  Future<File> _copyToReadableCache(XFile source) async {
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) {
      throw const RosterImageImportEmptyFileException();
    }

    final directory = await getTemporaryDirectory();
    final extension = p.extension(source.name).trim().isEmpty
        ? p.extension(source.path)
        : p.extension(source.name);
    final safeExtension = extension.trim().isEmpty ? '.jpg' : extension;
    final output = File(
      p.join(
        directory.path,
        'nizam_ocr_${DateTime.now().microsecondsSinceEpoch}$safeExtension',
      ),
    );
    return output.writeAsBytes(bytes, flush: true);
  }
}

class RosterImageImportUnsupportedException implements Exception {
  const RosterImageImportUnsupportedException();

  @override
  String toString() =>
      'Görselden aktarım yalnızca Android ve iOS cihazlarda kullanılabilir.';
}

class RosterImageImportNoNamesException implements Exception {
  const RosterImageImportNoNamesException();

  @override
  String toString() => 'Görselde eşleştirilecek personel adı bulunamadı.';
}

class RosterImageImportEmptyFileException implements Exception {
  const RosterImageImportEmptyFileException();

  @override
  String toString() => 'Seçilen görsel dosyası boş okunuyor.';
}
