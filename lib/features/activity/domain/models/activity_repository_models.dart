import 'package:personelapp2/core/database/database.dart';

enum ActivityDateChangeStatus {
  success,
  unchanged,
  activityNotFound,
  invalidDate,
}

class ActivityDateChangePreview {
  const ActivityDateChangePreview({
    required this.status,
    required this.oldDate,
    required this.newDate,
    required this.assignmentCount,
    required this.pendingAssignmentCount,
  });

  final ActivityDateChangeStatus status;
  final String oldDate;
  final String newDate;
  final int assignmentCount;
  final int pendingAssignmentCount;

  bool get canChange =>
      status == ActivityDateChangeStatus.success ||
      status == ActivityDateChangeStatus.unchanged;
}

class ActivityDateChangeResult extends ActivityDateChangePreview {
  const ActivityDateChangeResult({
    required super.status,
    required super.oldDate,
    required super.newDate,
    required super.assignmentCount,
    required super.pendingAssignmentCount,
  });
}

class ApprovalResult {
  const ApprovalResult({
    required this.approvedCount,
    required this.blockedCount,
    this.conflictDescriptions = const [],
  });

  final int approvedCount;
  final int blockedCount;
  final List<String> conflictDescriptions;

  bool get isFullyApproved => blockedCount == 0;
}

class ExistingActivityMatch {
  const ExistingActivityMatch({
    required this.activity,
    required this.newPersonnelCount,
    required this.unchangedPersonnelCount,
    required this.differentPersonnelCount,
  });

  final GunlukFaaliyetTableData activity;
  final int newPersonnelCount;
  final int unchangedPersonnelCount;
  final int differentPersonnelCount;
}

class ActivityMergeResult {
  const ActivityMergeResult({
    required this.activityId,
    required this.addedCount,
    required this.updatedCount,
    required this.skippedCount,
    this.unchangedCount = 0,
    this.conflictSkippedCount = 0,
    this.skippedPersonnelIds = const [],
  });

  final int activityId;
  final int addedCount;
  final int updatedCount;
  final int skippedCount;
  final int unchangedCount;
  final int conflictSkippedCount;
  final List<int> skippedPersonnelIds;
}

class ActivityBatchCreateResult {
  const ActivityBatchCreateResult({
    required this.activityIds,
    required this.addedAssignmentCount,
    required this.alreadyAssignedCount,
    required this.skippedAssignmentCount,
    this.conflictDescriptions = const [],
  });

  final List<int> activityIds;
  final int addedAssignmentCount;
  final int alreadyAssignedCount;
  final int skippedAssignmentCount;
  final List<String> conflictDescriptions;
}

class AssignmentConflictException implements Exception {
  const AssignmentConflictException(this.message);

  final String message;

  @override
  String toString() => message;
}
