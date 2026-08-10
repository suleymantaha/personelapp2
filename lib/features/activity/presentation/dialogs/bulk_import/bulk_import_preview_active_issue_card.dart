part of 'bulk_import_preview_section.dart';

class _ActiveIssueCard extends StatelessWidget {
  const _ActiveIssueCard({
    required this.problemLocations,
    required this.parseIssues,
    required this.activeIssueFocusIndex,
    required this.onFix,
  });

  final List<ProblemLocation> problemLocations;
  final List<BulkParseIssue> parseIssues;
  final int activeIssueFocusIndex;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    if (problemLocations.isEmpty && parseIssues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.approvedColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.approvedColor.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.task_alt_rounded, color: context.approvedColor),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tüm kontroller tamam',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    final showingParseIssue = problemLocations.isEmpty;
    final total =
        showingParseIssue ? parseIssues.length : problemLocations.length;
    final safeIndex =
        activeIssueFocusIndex < 0 ? 0 : activeIssueFocusIndex % total;
    final parseIssue = showingParseIssue ? parseIssues[safeIndex] : null;
    final issue = showingParseIssue ? null : problemLocations[safeIndex];
    final isCritical = parseIssue?.isBlocking ?? issue!.isCritical;
    final color = isCritical ? context.rejectedColor : context.pendingColor;
    final title = parseIssue?.message ?? _issueTitle(issue!);
    final reason = parseIssue == null
        ? _issueReason(issue!)
        : [
            if (parseIssue.rawLine.trim().isNotEmpty) parseIssue.rawLine.trim(),
            if (parseIssue.lineNumber > 0) 'Satır ${parseIssue.lineNumber}',
          ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isCritical ? Icons.error_rounded : Icons.info_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${safeIndex + 1} / $total',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isCritical ? 'Kritik' : 'İnceleme',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  softWrap: true,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reason,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  softWrap: true,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onFix,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            label: const Text(
              'Düzelt',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _issueTitle(ProblemLocation issue) {
    final text = issue.description;
    final dashIndex = text.indexOf(' - ');
    final withoutLine = text.replaceFirst(RegExp(r'^Satır \d+:\s*'), '');
    if (dashIndex >= 0) {
      return withoutLine.split(' - ').first.trim();
    }
    return withoutLine.trim();
  }

  static String _issueReason(ProblemLocation issue) {
    final parts = <String>[];
    final text = issue.description;
    final dashIndex = text.indexOf(' - ');
    if (dashIndex >= 0) {
      parts.add(text.substring(dashIndex + 3).trim());
    } else {
      parts.add(text);
    }
    if (issue.sourceLineNumber != null) {
      parts.add('Satır ${issue.sourceLineNumber}');
    }
    return parts.join(' • ');
  }
}
