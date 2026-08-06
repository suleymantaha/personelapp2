import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:personelapp2/core/utils/official_roster_title.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

/// Helper module for generating native binary .xlsx spreadsheets with OpenXML page setup
part 'excel_xlsx_military_generator.dart';
part 'excel_xlsx_master_generator.dart';
part 'excel_xlsx_support.dart';

/// Generates native XLSX workbooks for military activity rosters.
class ExcelXlsxGenerator {
  static List<int> generateMilitaryExcelBytes({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) =>
      _generateMilitaryExcelBytes(
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
      );

  static List<int> generateMasterDailyExcelBytes({
    required String title,
    required List<MasterActivityData> activities,
  }) =>
      _generateMasterDailyExcelBytes(title: title, activities: activities);
}
