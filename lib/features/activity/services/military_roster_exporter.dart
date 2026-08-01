import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:personelapp2/core/utils/official_roster_title.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/services/exporter/excel_html_generator.dart';
import 'package:personelapp2/features/activity/services/exporter/excel_xml_generator.dart';
import 'package:personelapp2/features/activity/services/exporter/excel_xlsx_generator.dart';
import 'package:share_plus/share_plus.dart';

class MilitaryRosterRow {
  MilitaryRosterRow({
    required this.sNu,
    required this.birligi,
    required this.rutbe,
    required this.adSoyad,
    required this.diger,
    this.groupCode = 'DIGER',
  });

  final int sNu;
  final String birligi;
  final String rutbe;
  final String adSoyad;
  final String diger;
  final String groupCode; // DIGER, NOBET_HEYETI, HAZIR_KITA, GULUSKUR
}

class MasterActivityData {
  MasterActivityData({
    required this.faaliyetAdi,
    required this.tarih,
    required this.olusturanKullanici,
    required this.rows,
    this.olusturmaTarihi = '',
  });

  final String faaliyetAdi;
  final String tarih;
  final String olusturanKullanici;
  final List<MilitaryRosterRow> rows;
  final String olusturmaTarihi;

  String get sectionHeader {
    final parsed = DateTime.tryParse(olusturmaTarihi);
    final time = parsed == null
        ? ''
        : '${parsed.hour.toString().padLeft(2, '0')}:'
            '${parsed.minute.toString().padLeft(2, '0')}';
    final details = [
      tarih,
      if (time.isNotEmpty) time,
      if (olusturanKullanici.trim().isNotEmpty) olusturanKullanici.trim(),
    ].join(' - ');
    return '${faaliyetAdi.toUpperCase()} ($details)';
  }
}

class MilitaryRosterExporter {
  static String escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static String formatOfficialTitle(String faaliyetAdi, String rawDate) {
    return OfficialRosterTitle.format(faaliyetAdi, rawDate);
  }

  static String specialDutyRankSummary(
    String label,
    String groupCode,
    List<MilitaryRosterRow> rows,
  ) {
    final groupRows = rows.where((row) => row.groupCode == groupCode).toList();
    final counts = RankSummaryCounts.calculate(
      groupRows.map((row) => row.rutbe).toList(),
    );
    return '$label: ${counts.totalCount} Personel '
        '(Subay: ${counts.subayCount} • '
        'Astsubay: ${counts.astsubayCount} • '
        'Uzman Jandarma: ${counts.uzmanJandarmaCount} • '
        'Uzman Erbaş: ${counts.uzmanErbasCount} • '
        'Diğer: ${counts.digerCount})';
  }

  /// Generates HTML Excel file (.xls) with UTF-8 BOM for native opening
  static String generateMilitaryHtmlExcel({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) =>
      ExcelHtmlGenerator.generate(
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
      );

  /// Generates SpreadsheetML XML (.xls)
  static String generateMilitaryXml({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) =>
      ExcelXmlGenerator.generate(
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
      );

  /// Generates plain text list
  static String generateMilitaryText({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) {
    final titleHeader = formatOfficialTitle(faaliyetAdi, tarih);
    final sb = StringBuffer()
      ..writeln('==============================================')
      ..writeln(titleHeader)
      ..writeln('==============================================')
      ..writeln(
        'S.NU | BİRLİĞİ          | RÜTBE        | ADI SOYADI            | DİĞER',
      )
      ..writeln(
        '----------------------------------------------------------------------',
      );

    for (final r in rows) {
      final sNuStr = r.sNu.toString().padRight(4);
      final birlikStr = r.birligi.padRight(16);
      final rutbeStr = r.rutbe.padRight(12);
      final adStr = r.adSoyad.padRight(22);
      sb.writeln('$sNuStr| $birlikStr| $rutbeStr| $adStr| ${r.diger}');
    }

    sb.writeln('==============================================');
    return sb.toString();
  }

  /// Generates native binary .xlsx spreadsheet
  static List<int> generateMilitaryExcelBytes({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) =>
      ExcelXlsxGenerator.generateMilitaryExcelBytes(
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
      );

  /// Generates native binary .xlsx spreadsheet for all daily activities combined
  static List<int> generateMasterDailyExcelBytes({
    required String title,
    required List<MasterActivityData> activities,
  }) =>
      ExcelXlsxGenerator.generateMasterDailyExcelBytes(
        title: title,
        activities: activities,
      );

  /// Exports Excel roster with native binary .xlsx and triggers OS share
  static Future<void> shareExcelRoster({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    final bytes = generateMilitaryExcelBytes(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
    );

    final dir = await getTemporaryDirectory();
    final sanitizedTitle = faaliyetAdi.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final exportId = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${dir.path}/${sanitizedTitle}_Listesi_${tarih}_$exportId.xlsx',
    );
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$faaliyetAdi - Resmi İsim Listesi Excel Dökümanı',
      ),
    );
  }

  /// Saves Excel file directly to the device's public Downloads / Storage folder
  static Future<File> saveExcelToDevice({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    final bytes = generateMilitaryExcelBytes(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
    );

    final sanitizedTitle = faaliyetAdi.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final fileName = '${sanitizedTitle}_Listesi_$tarih.xlsx';

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
    return file;
  }

  /// Master XML generator helper
  static String generateMasterDailyXml({
    required String title,
    required List<MasterActivityData> activities,
  }) =>
      ExcelXmlGenerator.generateMasterDailyXml(
        title: title,
        activities: activities,
      );

  /// Shares Master Daily Excel containing all activities
  static Future<void> shareMasterDailyExcel({
    required String title,
    required String dateStr,
    required List<MasterActivityData> activities,
  }) async {
    final bytes = generateMasterDailyExcelBytes(
      title: title,
      activities: activities,
    );

    final dir = await getTemporaryDirectory();
    final exportId = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${dir.path}/Gunluk_Tum_Faaliyetler_${dateStr}_$exportId.xlsx',
    );
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$title - Günlük Tüm Faaliyetler Birleşik Excel Dökümanı',
      ),
    );
  }

  /// Shares formatted text roster
  static Future<void> shareTextRoster({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    final text = generateMilitaryText(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
    );
    await SharePlus.instance.share(
      ShareParams(text: text),
    );
  }
}
