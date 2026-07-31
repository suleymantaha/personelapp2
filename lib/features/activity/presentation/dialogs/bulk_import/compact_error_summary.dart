import 'package:flutter/material.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

class CompactErrorSummary extends StatelessWidget {
  const CompactErrorSummary({
    required this.problemCount,
    required this.warningCount,
    required this.parseIssues,
    required this.isExpanded,
    required this.onToggle,
    required this.onStartWizard,
    required this.totalIssues,
    required this.currentIndex,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final int problemCount;
  final int warningCount;
  final List<BulkParseIssue> parseIssues;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback? onStartWizard;
  final int totalIssues;
  final int currentIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

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
            onTap: onToggle,
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
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: parseIssues.isNotEmpty
                  ? ListView.separated(
                      shrinkWrap: true,
                      itemCount: parseIssues.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final issue = parseIssues[index];
                        return Text(
                          '${issue.lineNumber > 0 ? 'Satır ${issue.lineNumber}: ' : ''}'
                          '${issue.message}'
                          '${issue.rawLine.trim().isEmpty ? '' : '\n${issue.rawLine.trim()}'}',
                          style: TextStyle(color: textColor, fontSize: 12),
                        );
                      },
                    )
                  : Text(
                      'Lütfen aşağıda vurgulanan kartlardaki eksik personelleri eşleştirin, tekrarları düzeltin veya boş kartları silin.',
                      style: TextStyle(color: textColor, fontSize: 12),
                    ),
            ),
          if (hasProblems && onStartWizard != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('bulk-wizard-prev'),
                      onPressed: onPrevious,
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                      label: const Text('Önceki'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: const Key('bulk-wizard-next'),
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(
                        currentIndex < 0 ? 'Başlat' : 'Sonraki Sorun',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: textColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
