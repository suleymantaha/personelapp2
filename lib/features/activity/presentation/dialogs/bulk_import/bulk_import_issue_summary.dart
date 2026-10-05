import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

import 'bulk_import_problem_wizard.dart';

/// Counts editable card problems and independent source diagnostics once.
class BulkImportIssueSummary {
  BulkImportIssueSummary({
    required List<ProblemLocation> locations,
    required List<BulkParseIssue> issues,
  }) {
    final sourceIssues = locations.isEmpty
        ? issues
        : issues.where((issue) => !_cardIssueCodes.contains(issue.code));
    criticalCount =
        locations.where((location) => location.isCritical).length +
        sourceIssues.where((issue) => issue.isBlocking).length;
    reviewCount =
        locations.where((location) => !location.isCritical).length +
        sourceIssues.where((issue) => !issue.isBlocking).length;
  }

  static const _cardIssueCodes = {
    'empty_block',
    'missing_date',
    'unknown_team',
    'unknown_activity',
    'unmatched_personnel',
  };
  late final int criticalCount;
  late final int reviewCount;
  int get totalCount => criticalCount + reviewCount;
  bool get hasBlocking => criticalCount > 0;
}
