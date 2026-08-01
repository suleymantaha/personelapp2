import 'package:flutter/material.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart';

class CompactErrorSummary extends StatelessWidget {
  const CompactErrorSummary({
    required this.problemCount,
    required this.warningCount,
    required this.parseIssues,
    required this.isExpanded,
    required this.onToggle,
    required this.totalIssues,
    required this.currentIndex,
    this.problemLocations = const [],
    this.onStartWizard,
    this.onConfirmAllSuggestions,
    this.onSelectIssue,
    super.key,
  });

  final int problemCount;
  final int warningCount;
  final List<BulkParseIssue> parseIssues;
  final List<ProblemLocation> problemLocations;
  final bool isExpanded;
  final VoidCallback onToggle;
  final int totalIssues;
  final int currentIndex;
  final VoidCallback? onStartWizard;
  final VoidCallback? onConfirmAllSuggestions;
  final void Function(int index)? onSelectIssue;

  @override
  Widget build(BuildContext context) {
    final hasBlocking = parseIssues.any((issue) => issue.isBlocking);
    final hasProblems = problemCount > 0;
    final hasWarnings = warningCount > 0;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    if (hasBlocking || hasProblems) {
      bgColor = const Color(0xFFD32F2F).withValues(alpha: 0.08);
      borderColor = const Color(0xFFD32F2F).withValues(alpha: 0.3);
      textColor = const Color(0xFFD32F2F);
      icon = Icons.error_rounded;
      title = 'Kaydedilemiyor';
      subtitle = '$problemCount kritik hata';
    } else if (hasWarnings) {
      bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.08);
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.3);
      textColor = const Color(0xFFF59E0B);
      icon = Icons.warning_amber_rounded;
      title = '$warningCount uyarı';
      subtitle = 'Kayıt yapılabilir';
    } else {
      bgColor = const Color(0xFF16A34A).withValues(alpha: 0.08);
      borderColor = const Color(0xFF16A34A).withValues(alpha: 0.3);
      textColor = const Color(0xFF16A34A);
      icon = Icons.task_alt_rounded;
      title = 'Tüm kontroller tamam';
      subtitle = 'Kayda hazır';
    }

    final displayTotal = totalIssues > 0 ? totalIssues : problemCount;
    final displayIndex = currentIndex < 0
        ? 1
        : (displayTotal > 0 ? (currentIndex % displayTotal) + 1 : 1);

    final allDisplayItems = <String>[];
    for (final issue in parseIssues) {
      final lineText = issue.lineNumber > 0 ? 'Satır ${issue.lineNumber}: ' : '';
      allDisplayItems.add('$lineText${issue.message}');
    }
    for (final loc in problemLocations) {
      allDisplayItems.add(loc.description);
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              onToggle();
              if (onStartWizard != null) {
                onStartWizard!();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasProblems)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$displayIndex/$displayTotal',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (onConfirmAllSuggestions != null) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      key: const Key('bulk-confirm-all-suggestions'),
                      onPressed: onConfirmAllSuggestions,
                      icon: const Icon(Icons.done_all_rounded, size: 14),
                      label: const Text(
                        'Tümünü Onayla',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: textColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: allDisplayItems.isNotEmpty
                  ? ListView.separated(
                      shrinkWrap: true,
                      itemCount: allDisplayItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 10),
                      itemBuilder: (context, index) {
                        final text = allDisplayItems[index];
                        final isCurrentlyFocused = currentIndex >= 0 &&
                            index == (currentIndex % allDisplayItems.length);
                        return InkWell(
                          onTap: onSelectIssue != null
                              ? () => onSelectIssue!(index)
                              : null,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCurrentlyFocused
                                      ? Icons.arrow_right_rounded
                                      : Icons.circle,
                                  size: isCurrentlyFocused ? 18 : 6,
                                  color: textColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontWeight: isCurrentlyFocused
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Text(
                      'Lütfen aşağıda vurgulanan kartlardaki eksik personelleri eşleştirin, tekrarları düzeltin veya boş kartları silin.',
                      style: TextStyle(color: textColor, fontSize: 12),
                    ),
            ),
        ],
      ),
    );
  }
}
