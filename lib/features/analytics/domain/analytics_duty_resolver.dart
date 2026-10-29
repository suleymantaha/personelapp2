import 'package:personelapp2/core/utils/military_rank_normalizer.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'monthly_analytics_rows.dart';

/// Projects a proven legacy personnel-line import error without changing source
/// assignments. A recognized task override always wins over its activity title.
class AnalyticsDutyResolver {
  AnalyticsDutyResolver(Iterable<String> personnelNames)
      : _personnelNames = personnelNames.map(_nameKey).toSet();
  final Set<String> _personnelNames;

  String resolve({required String duty, required String activityName}) {
    final label = analyticsDutyLabel(duty);
    if (isClassifiedAnalyticsDuty(label)) return label;
    final parentDuty = analyticsDutyLabel(activityName);
    if (!isClassifiedAnalyticsDuty(parentDuty) ||
        !DutyOrLeaveType.isOperationalDuty(parentDuty)) {
      return label;
    }
    final working = MilitaryRankNormalizer.stripLeadingSequence(duty);
    final parsed = MilitaryRankNormalizer.extractRankAndName(working);
    final rawRank = parsed.rawRank;
    if (!parsed.hasRank || rawRank == null || parsed.cleanName.isEmpty) {
      return label;
    }
    // The normalizer also accepts compact ranks. Reject accidental word-prefix
    // matches such as "ERKEN" being parsed as rank "Er" plus a name.
    final following = working.substring(rawRank.length);
    if (!rawRank.endsWith('.') &&
        following.isNotEmpty &&
        !RegExp(r'^\s').hasMatch(following)) {
      return label;
    }
    return _personnelNames.contains(_nameKey(parsed.cleanName))
        ? parentDuty
        : label;
  }

  static String _nameKey(String value) => value
      .trim()
      .toUpperCase()
      .replaceAll('İ', 'I')
      .replaceAll(RegExp(r'\s+'), ' ');
}
