import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';

class TeamDutyCalendarSummary extends StatelessWidget {
  const TeamDutyCalendarSummary({required this.summary, super.key});

  final TeamDutySummaryDto summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.accentSubtleBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CalendarStatItem(
                  label: context.l10n.matrixDutyDay,
                  value: context.l10n.matrixDutyDayCount(summary.toplamGorevGunSayisi),
                  icon: Icons.assignment_outlined,
                ),
                _CalendarStatItem(
                  label: 'Aktif Personel',
                  value: context.l10n.matrixActivePersonnelCount(summary.aktifPersonelSayisi),
                  icon: Icons.groups_outlined,
                ),
                _CalendarStatItem(
                  label: context.l10n.matrixPersonnelDayRatio,
                  value:
                      summary.yukHesabiTam
                          ? '%${summary.ortalamaYukYuzdesi.toStringAsFixed(0)}'
                          : 'Veri eksik',
                  icon: Icons.speed_rounded,
                  valueColor:
                      summary.ortalamaYukYuzdesi > 70
                          ? context.rejectedColor
                          : (summary.ortalamaYukYuzdesi > 40
                              ? context.warningColor
                              : context.approvedColor),
                ),
              ],
            ),
            if (summary.bilinmeyenTimAtamaSayisi > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.l10n.matrixUnknownSquadAssignmentsNotice(summary.bilinmeyenTimAtamaSayisi),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarStatItem extends StatelessWidget {
  const _CalendarStatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: context.accentOrOlive),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
