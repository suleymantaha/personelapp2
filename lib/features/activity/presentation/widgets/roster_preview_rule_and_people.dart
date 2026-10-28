import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_matrix_x_rule.dart';

class RosterPreviewRuleCard extends StatelessWidget {
  const RosterPreviewRuleCard({
    super.key,
    required this.month,
    required this.result,
    required this.busy,
    required this.onPreview,
    required this.onReset,
    required this.onShowIncluded,
    required this.onShowExcluded,
  });

  final String month;
  final RosterMatrixXResult? result;
  final bool busy;
  final VoidCallback onPreview;
  final VoidCallback onReset;
  final VoidCallback onShowIncluded;
  final VoidCallback onShowExcluded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      color: Color.alphaBlend(
        context.accentOrOlive.withValues(alpha: 0.09),
        scheme.surface,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: context.accentOrOlive.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    size: 20, color: context.accentOrOlive),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.rosterRuleMonthTitle(month),
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.accentOrOlive),
                  ),
                  child: Text(
                    '21+ X',
                    style: text.titleMedium?.copyWith(
                      color: context.accentOrOlive,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(context.l10n.rosterRuleDescription, style: text.bodySmall),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('roster-rule-included-count'),
                      onTap: onShowIncluded,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 18, color: context.accentOrOlive),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                context.l10n.rosterRuleIncludedCount(
                                    result!.rows.length),
                                style: text.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 28, color: scheme.outlineVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      key: const Key('roster-rule-excluded-count'),
                      onTap: onShowExcluded,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.person_off_outlined,
                                size: 18, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                context.l10n.rosterRuleExcludedCount(
                                    result!.excludedCount),
                                style: text.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (result!.rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(context.l10n.rosterRuleEmpty),
                ),
            ],
            if (result != null) ...[
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                children: [
                  TextButton.icon(
                    key: const Key('roster-matrix-rule-refresh'),
                    onPressed: busy ? null : onPreview,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(context.l10n.rosterRuleRefreshAction),
                  ),
                  TextButton(
                    key: const Key('roster-rule-reset'),
                    onPressed: busy ? null : onReset,
                    child: Text(context.l10n.rosterRuleBackToNormal),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RosterPreviewPeople extends StatelessWidget {
  const RosterPreviewPeople({
    super.key,
    required this.rows,
    required this.showAll,
    required this.onToggleAll,
  });

  final List<MilitaryRosterRow> rows;
  final bool showAll;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          children: [
            InkWell(
              key: const Key('roster-preview-people-toggle'),
              onTap: onToggleAll,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${context.l10n.rosterPreviewPeopleTitle} · ${rows.length}',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(showAll
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
            if (showAll && rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(context.l10n.rosterRuleEmpty),
              ),
            for (final row in showAll ? rows : <MilitaryRosterRow>[])
              ListTile(
                key: Key('roster-person-${row.personelId}'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: CircleAvatar(
                  backgroundColor: context.accentSubtleBg,
                  child: Text('${row.sNu}'),
                ),
                title: Text(row.adSoyad),
                subtitle: Text(row.rutbe),
              ),
          ],
        ),
      ),
    );
  }
}
