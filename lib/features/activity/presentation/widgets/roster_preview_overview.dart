import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class RosterPreviewOverview extends StatelessWidget {
  const RosterPreviewOverview({
    super.key,
    required this.peopleCount,
    required this.sources,
    required this.expanded,
    required this.onToggleCards,
  });

  final int peopleCount;
  final List<GunlukFaaliyetTableData> sources;
  final bool expanded;
  final VoidCallback onToggleCards;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Card(
          key: const Key('roster-preview-summary'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _Metric(
                    icon: Icons.people_alt_outlined,
                    count: peopleCount,
                    label: context.l10n.rosterPreviewPeopleLabel,
                  ),
                ),
                Container(width: 1, height: 38, color: scheme.outlineVariant),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: _Metric(
                      icon: Icons.article_outlined,
                      count: sources.length,
                      label: context.l10n.rosterPreviewCardsSelectedLabel,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              InkWell(
                key: const Key('roster-preview-cards-toggle'),
                onTap: onToggleCards,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      const Icon(Icons.library_books_outlined, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${context.l10n.rosterPreviewSelectedCards} · ${sources.length}',
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
              ),
              if (expanded) ...[
                Divider(height: 1, color: scheme.outlineVariant),
                for (final source in sources)
                  ListTile(
                    dense: true,
                    title: Text(source.faaliyetAdi),
                    subtitle: Text(
                      DateFormat('dd.MM.yyyy')
                          .format(DateTime.parse(source.tarih)),
                      style: text.bodySmall?.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: context.accentOrOlive, size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(label, style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
