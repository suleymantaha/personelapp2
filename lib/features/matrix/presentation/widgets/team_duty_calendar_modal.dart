import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/duty_abbreviation_mapper.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';

import 'team_duty_calendar_summary.dart';
import 'team_duty_day_details.dart';

class TeamDutyCalendarModal extends StatefulWidget {
  const TeamDutyCalendarModal({super.key, required this.calendarData});

  final TeamMonthlyCalendarDto calendarData;

  static Future<void> show(
    BuildContext context, {
    required TeamMonthlyCalendarDto calendarData,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TeamDutyCalendarModal(calendarData: calendarData),
    );
  }

  @override
  State<TeamDutyCalendarModal> createState() => _TeamDutyCalendarModalState();
}

class _TeamDutyCalendarModalState extends State<TeamDutyCalendarModal> {
  int? _selectedDayIndex;

  String _monthName(int month) =>
      DateFormat('MMMM', 'tr_TR').format(DateTime(2024, month));

  Future<void> _showDay(
    BuildContext context,
    TeamDayDutyDto day,
    String monthName,
  ) async {
    setState(() => _selectedDayIndex = day.gunIndex);
    await TeamDutyDayDetails.show(
      context,
      day: day,
      monthName: monthName,
      year: widget.calendarData.yil,
    );
  }

  String _dutyLabel(TeamDayDutyDto day) {
    if (day.gorevGruplari.isEmpty) return day.gorevKodu;
    final code =
        DutyAbbreviationMapper.getAbbreviation(day.gorevGruplari.first.gorev);
    final remaining = day.gorevGruplari.length - 1;
    return remaining > 0 ? '$code +$remaining' : code;
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _monthName(widget.calendarData.ay);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final daysInMonth =
        DateTime(widget.calendarData.yil, widget.calendarData.ay + 1, 0).day;
    // DateTime.weekday: Monday = 1. The calendar starts on Monday.
    final leadingDays =
        DateTime(widget.calendarData.yil, widget.calendarData.ay).weekday - 1;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final daysByNumber = <int, TeamDayDutyDto>{
      for (final day in widget.calendarData.gunler) day.gunIndex: day,
    };

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.90,
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
            padding: const EdgeInsets.fromLTRB(16, 2, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.accentOrOlive.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_month_rounded,
                      size: 21, color: context.accentOrOlive),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.matrixTeamDutyCalendarTitle(
                            widget.calendarData.timAdi),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$monthName ${widget.calendarData.yil}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TeamDutyCalendarSummary(summary: widget.calendarData.ozet),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                    child: Text(
                      context.l10n.matrixMonthlyDailyDistribution,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Row(
                    children: const [
                      'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz',
                    ].map((name) => Expanded(
                      child: Center(
                        child: Text(name,
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 4.0;
                      final cellWidth = (constraints.maxWidth - 6 * gap) / 7;
                      return GridView.builder(
                        key: const ValueKey('team-monthly-calendar-grid'),
                        itemCount: cellCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                          mainAxisExtent: cellWidth.clamp(42.0, 58.0),
                        ),
                        itemBuilder: (context, index) {
                          final dayNumber = index - leadingDays + 1;
                          if (dayNumber < 1 || dayNumber > daysInMonth) {
                            return const SizedBox.shrink();
                          }
                          final day = daysByNumber[dayNumber];
                          final hasDuty =
                              day != null && day.gorevKodu.isNotEmpty;
                          final selected = dayNumber == _selectedDayIndex;
                          final color = hasDuty
                              ? DutyAbbreviationMapper.getTextColor(
                                  day.gorevTamAdi,
                                  isDark: isDark,
                                )
                              : context.textSecondary;
                          final background = hasDuty
                              ? DutyAbbreviationMapper.getBadgeBgColor(
                                  day.gorevTamAdi,
                                  isDark: isDark,
                                )
                              : context.colorScheme.surfaceContainer;
                          return Semantics(
                            button: day != null,
                            label: '$dayNumber $monthName${hasDuty ? ', ${day!.gorevTamAdi}' : ''}',
                            child: InkWell(
                              key: ValueKey('team-calendar-day-$dayNumber'),
                              onTap: day == null
                                  ? null
                                  : () => _showDay(context, day, monthName),
                              borderRadius: BorderRadius.circular(10),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: selected
                                      ? context.accentOrOlive
                                          .withValues(alpha: 0.18)
                                      : background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? context.accentOrOlive
                                        : (hasDuty
                                            ? color.withValues(alpha: 0.30)
                                            : context.cardBorderColor),
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$dayNumber',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    if (hasDuty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _dutyLabel(day),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9,
                                        ),
                                      ),
                                      Text(
                                        '${day.gorevliPersonelAdlari.length}',
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        '–',
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      context.l10n.matrixClickDayForDetails,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
