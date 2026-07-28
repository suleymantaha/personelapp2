import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

class MatrixDayEntry {
  const MatrixDayEntry({
    required this.activityId,
    required this.activityName,
    required this.duty,
    required this.assignmentStatus,
    required this.sourceDate,
    required this.isContinuationDay,
    this.note,
  });

  final int activityId;
  final String activityName;
  final String duty;
  final String assignmentStatus;
  final String sourceDate;
  final bool isContinuationDay;
  final String? note;

  bool get isPending => assignmentStatus == AssignmentStatus.beklemede;
}

class MatrixDayCell {
  const MatrixDayCell({
    required this.displayCode,
    required this.entries,
    required this.hasConflict,
  });

  final String displayCode;
  final List<MatrixDayEntry> entries;
  final bool hasConflict;

  factory MatrixDayCell.fromEntries(List<MatrixDayEntry> entries) {
    final sorted = List<MatrixDayEntry>.from(entries)
      ..sort((a, b) {
        final statusA = _statusWeight(a.assignmentStatus);
        final statusB = _statusWeight(b.assignmentStatus);
        if (statusA != statusB) return statusA.compareTo(statusB);
        return a.activityId.compareTo(b.activityId);
      });
    final approved = sorted.where(
      (entry) => entry.assignmentStatus == AssignmentStatus.onaylandi,
    );
    final displayEntry = approved.firstOrNull ?? sorted.first;
    return MatrixDayCell(
      displayCode: _codeForEntry(displayEntry),
      entries: List.unmodifiable(sorted),
      hasConflict: sorted.length > 1 || sorted.any((entry) => entry.isPending),
    );
  }

  static int _statusWeight(String status) =>
      status == AssignmentStatus.onaylandi ? 0 : 1;

  static String _codeForEntry(MatrixDayEntry entry) {
    if (entry.isPending) return 'B';
    final duty = entry.duty.toUpperCase();
    if (duty.contains('İZİN')) return 'İZ';
    if (duty.contains('İSTİRAHAT')) return 'İST';
    if (duty.contains('RAPOR')) return 'RAP';
    if (duty.contains('SEVK')) return 'SVK';
    return 'X';
  }
}
