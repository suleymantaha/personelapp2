import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';

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

  Widget _people(BuildContext context, TeamDutyGroupDto group) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (var i = 0; i < group.personelAdlari.length; i++)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Text(
            '${group.personelAdlari[i]}${group.personelIds.length > i && group.personelAdlari.where((name) => name == group.personelAdlari[i]).length > 1 ? ' (#${group.personelIds[i]})' : ''}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups =
        day.gorevGruplari.isEmpty
            ? [
              TeamDutyGroupDto(
                gorev: day.gorevTamAdi,
                durum: 'onaylandi',
                personelIds: const [],
                personelAdlari: day.gorevliPersonelAdlari,
              ),
            ]
            : day.gorevGruplari;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.28,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${day.gunIndex} $monthName $year • ${day.gorevTamAdi}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${day.gorevliPersonelAdlari.length} Personel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.accentOrOlive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Expanded(
                child:
                    day.gorevliPersonelAdlari.isEmpty
                        ? Center(
                          child: Text(
                            context.l10n.matrixNoDutyPersonnelOnDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        )
                        : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final group in groups) ...[
                                Text(
                                  '${group.personelAdlari.length} ${group.gorev} • ${switch (group.durum) {
                                    'onaylandi' => context.l10n.statusApproved,
                                    'beklemede' => context.l10n.statusPending,
                                    'reddedildi' => context.l10n.statusRejected,
                                    _ => group.durum,
                                  }}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        group.durum == 'beklemede'
                                            ? context.warningColor
                                            : context.textPrimary,
                                  ),
                                ),
                                if (group.devamEdenPersonelIds.isNotEmpty)
                                  Text(
                                    context.l10n.matrixContinuingFromPreviousDay(group.devamEdenPersonelIds.length),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                const SizedBox(height: 6),
                                _people(context, group),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
