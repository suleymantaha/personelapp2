import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

typedef ParsedActivityTitle = ({
  String? timName,
  String activityType,
  String? date,
  bool activityTypeKnown,
});

enum BulkParseIssueSeverity { warning, error }

class BulkParseIssue {
  const BulkParseIssue({
    required this.lineNumber,
    required this.rawLine,
    required this.code,
    required this.message,
    required this.severity,
  });

  final int lineNumber;
  final String rawLine;
  final String code;
  final String message;
  final BulkParseIssueSeverity severity;

  bool get isBlocking => severity == BulkParseIssueSeverity.error;
}

class BulkParseResult {
  const BulkParseResult({
    required this.blocks,
    required this.issues,
    this.ignoredLineCount = 0,
    this.declaredTotals = const [],
  });

  final List<ParsedActivityBlock> blocks;
  final List<BulkParseIssue> issues;
  final int ignoredLineCount;
  final List<BulkDeclaredTotal> declaredTotals;

  bool get hasBlockingIssues => issues.any((issue) => issue.isBlocking);
}

class BulkDeclaredTotal {
  const BulkDeclaredTotal({
    required this.lineNumber,
    required this.expectedCount,
    required this.date,
    required this.teamName,
    required this.activityType,
  });

  final int lineNumber;
  final int expectedCount;
  final String date;
  final String teamName;
  final String activityType;
}

class PersonnelListParseResult {
  const PersonnelListParseResult({
    required this.personnel,
    required this.issues,
  });

  final List<ParsedPersonnelItem> personnel;
  final List<BulkParseIssue> issues;

  bool get hasPersonnel => personnel.isNotEmpty;
}
