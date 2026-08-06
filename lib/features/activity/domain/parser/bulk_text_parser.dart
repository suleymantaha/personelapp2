import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_parse_models.dart';

export 'package:personelapp2/features/activity/domain/parser/bulk_parse_models.dart';

part 'bulk_text_title_parser.dart';
part 'bulk_text_block_parser.dart';
part 'bulk_text_personnel_parser.dart';

class BulkTextParser {
  static ParsedActivityTitle parseTitle(
    String titleLine, [
    String? defaultDate,
  ]) =>
      _parseBulkTitle(titleLine, defaultDate);

  static String extractActivityType(String titleLine) =>
      _extractBulkActivityType(titleLine);

  static String mapActivityTypeToDutyOrLeave(String activityType) =>
      _mapBulkActivityTypeToDutyOrLeave(activityType);

  static BulkParseResult parse(
    String rawText, {
    String? defaultDate,
  }) =>
      _parseBulkText(rawText, defaultDate: defaultDate);

  static PersonnelListParseResult parsePersonnelList(String rawText) =>
      _parsePersonnelList(rawText);
}
