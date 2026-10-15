import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';

/// Compact, responsive summary which does not compete with the calendar.
class TeamDutyCalendarSummary extends StatelessWidget {
  const TeamDutyCalendarSummary({required this.summary, super.key});

  final TeamDutySummaryDto summary;

  @override
  Widget build(BuildContext context) {
    final ratioComplete = summary.yukHesabiTam;
    final ratioColor = !ratioComplete
        ? context.warningColor
        : summary.ortalamaYukYuzdesi > 70
            ? context.rejectedColor
            : summary.ortalamaYukYuzdesi > 40
                ? context.warningColor
                : context.approvedColor;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        color: context.accentSubtleBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.event_available_outlined,
                  value: context.l10n.matrixDutyDayCount(
                      summary.toplamGorevGunSayisi),
                  label: context.l10n.matrixDutyDay,
                ),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.groups_outlined,
                  value: context.l10n.matrixActivePersonnelCount(
                      summary.aktifPersonelSayisi),
                  label: context.l10n.monthlyMatrixActivePersonnelLabel,
                ),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.speed_rounded,
                  value: ratioComplete
                      ? '%${summary.ortalamaYukYuzdesi.toStringAsFixed(0)}'
                      : context.l10n.monthlyMatrixMissingData,
                  label: context.l10n.matrixPersonnelDayRatio,
                  valueColor: ratioColor,
                ),
              ),
            ],
          ),
          if (summary.bilinmeyenTimAtamaSayisi > 0) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: context.cardBorderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 9, 7, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 17, color: context.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.matrixUnknownSquadAssignmentsNotice(
                          summary.bilinmeyenTimAtamaSayisi),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: context.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: valueColor ?? context.accentOrOlive),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor ?? context.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}
