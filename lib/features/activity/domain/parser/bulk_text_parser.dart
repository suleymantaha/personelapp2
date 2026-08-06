import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_parse_models.dart';

export 'package:personelapp2/features/activity/domain/parser/bulk_parse_models.dart';

part 'bulk_text_parser_engine.dart';

class BulkTextParser {
  static ParsedActivityTitle parseTitle(
    String titleLine, [
    String? defaultDate,
  ]) =>
      _BulkTextParserEngine.parseTitle(titleLine, defaultDate);

  static String extractActivityType(String titleLine) =>
      _BulkTextParserEngine.extractActivityType(titleLine);

  static String mapActivityTypeToDutyOrLeave(String activityType) =>
      _BulkTextParserEngine.mapActivityTypeToDutyOrLeave(activityType);

  static BulkParseResult parse(
    String rawText, {
    String? defaultDate,
  }) =>
      _BulkTextParserEngine.parse(rawText, defaultDate: defaultDate);

  static PersonnelListParseResult parsePersonnelList(String rawText) =>
      _BulkTextParserEngine.parsePersonnelList(rawText);
}
