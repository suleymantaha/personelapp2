import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';

/// Standalone day sheet: the calendar remains full height behind this route.
class TeamDutyDayDetails extends StatelessWidget {
  const TeamDutyDayDetails({
    required this.day,
    required this.monthName,
    required this.year,
    super.key,
  });

  final TeamDayDutyDto day;
  final String monthName;
  final int year;

  static Future<void> show(
    BuildContext context, {
    required TeamDayDutyDto day,
    required String monthName,
    required int year,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      // Do not dim the already-open calendar a second time.
      barrierColor: Colors.transparent,
      builder: (context) => TeamDutyDayDetails(
        day: day,
        monthName: monthName,
        year: year,
      ),
    );
  }

  String _statusLabel(BuildContext context, String status) => switch (status) {
        'onaylandi' => context.l10n.statusApproved,
        'beklemede' => context.l10n.statusPending,
        'reddedildi' => context.l10n.statusRejected,
        _ => status,
      };

  Color _statusColor(BuildContext context, String status) => switch (status) {
        'onaylandi' => context.approvedColor,
        'beklemede' => context.warningColor,
        'reddedildi' => context.rejectedColor,
        _ => context.textSecondary,
      };

  Widget _personChip(
    BuildContext context,
    TeamDutyGroupDto group,
    int index,
    int groupIndex,
  ) {
    final name = group.personelAdlari[index];
    final isDuplicate =
        group.personelAdlari.where((value) => value == name).length > 1;
    final id = group.personelIds.length > index
        ? group.personelIds[index]
        : null;
    final label = isDuplicate && id != null ? '$name (#$id)' : name;

    return ConstrainedBox(
      key: ValueKey('team-day-person-chip-$groupIndex-$index'),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 64,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 16, color: context.textSecondary),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = day.gorevGruplari.isEmpty &&
            day.gorevliPersonelAdlari.isNotEmpty
        ? [
            TeamDutyGroupDto(
              gorev: day.gorevTamAdi,
              durum: 'onaylandi',
              personelIds: const [],
              personelAdlari: day.gorevliPersonelAdlari,
            ),
          ]
        : day.gorevGruplari;

    return DraggableScrollableSheet(
      key: const ValueKey('team-day-detail-sheet'),
      expand: false,
      initialChildSize: 0.52,
      minChildSize: 0.28,
      maxChildSize: 0.88,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 9, bottom: 5),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.accentOrOlive.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.event_available_outlined,
                        color: context.accentOrOlive, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${day.gunIndex} $monthName $year',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (day.gorevTamAdi.isNotEmpty)
                          Text(
                            day.gorevTamAdi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.accentOrOlive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.l10n.bulkImportBlockPersonnelCount(
                          day.gorevliPersonelAdlari.length),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: context.accentOrOlive,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          context.l10n.matrixNoDutyPersonnelOnDate,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  for (var groupIndex = 0;
                      groupIndex < groups.length;
                      groupIndex++) ...[
                    Builder(builder: (context) {
                      final group = groups[groupIndex];
                      final statusColor =
                          _statusColor(context, group.durum);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.cardBorderColor),
                        ),
                        child: ExpansionTile(
                          key: ValueKey('team-day-group-$groupIndex'),
                          initiallyExpanded: groupIndex == 0,
                          shape: const Border(),
                          collapsedShape: const Border(),
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            12, 0, 12, 12,
                          ),
                          title: Text(
                            group.gorev,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                context.l10n.bulkImportBlockPersonnelCount(
                                  group.personelAdlari.length,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _statusLabel(context, group.durum),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          children: [
                            if (group.devamEdenPersonelIds.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    context.l10n.matrixContinuingFromPreviousDay(
                                      group.devamEdenPersonelIds.length,
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (var i = 0;
                                      i < group.personelAdlari.length;
                                      i++)
                                    _personChip(context, group, i, groupIndex),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
