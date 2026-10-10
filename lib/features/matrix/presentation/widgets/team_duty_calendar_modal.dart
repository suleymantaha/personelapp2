import 'package:intl/intl.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'team_duty_day_details.dart';
import 'team_duty_calendar_summary.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/duty_abbreviation_mapper.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';

class TeamDutyCalendarModal extends StatefulWidget {
  const TeamDutyCalendarModal({super.key, required this.calendarData});

  final TeamMonthlyCalendarDto calendarData;

  static Future<void> show(
    BuildContext context, {
    required TeamMonthlyCalendarDto calendarData,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TeamDutyCalendarModal(calendarData: calendarData),
    );
  }

  @override
  State<TeamDutyCalendarModal> createState() => _TeamDutyCalendarModalState();
}

class _TeamDutyCalendarModalState extends State<TeamDutyCalendarModal> {
  TeamDayDutyDto? selectedDay;

  String _getAyAdi(int month) {
    if (month >= 1 && month <= 12) {
      return DateFormat('MMMM', 'tr_TR').format(DateTime(2024, month));
    }
    return '$month.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ayAdi = _getAyAdi(widget.calendarData.ay);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Üst Başlık ve Sürükleme Tutamağı
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.accentOrOlive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: context.accentOrOlive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.matrixTeamDutyCalendarTitle(widget.calendarData.timAdi),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.l10n.matrixMonthlyOperationalView(widget.calendarData.yil, ayAdi),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Analitik Özet Kartı
          TeamDutyCalendarSummary(summary: widget.calendarData.ozet),

          // Takvim Grid Alanı
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.matrixMonthlyDailyDistribution,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.l10n.matrixClickDayForDetails,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      itemCount: widget.calendarData.gunler.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                      itemBuilder: (context, index) {
                        final dayDto = widget.calendarData.gunler[index];
                        final hasDuty = dayDto.gorevKodu.isNotEmpty;
                        final isSelected =
                            selectedDay?.gunIndex == dayDto.gunIndex;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedDay = dayDto;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? context.accentOrOlive.withValues(
                                        alpha: 0.2,
                                      )
                                      : (hasDuty
                                          ? DutyAbbreviationMapper.getBadgeBgColor(
                                            dayDto.gorevTamAdi,
                                            isDark: isDark,
                                          )
                                          : (context
                                              .colorScheme
                                              .surfaceContainer)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? context.accentOrOlive
                                        : (hasDuty
                                            ? DutyAbbreviationMapper.getTextColor(
                                              dayDto.gorevTamAdi,
                                              isDark: isDark,
                                            ).withValues(alpha: 0.3)
                                            : Colors.transparent),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${dayDto.gunIndex}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (hasDuty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          DutyAbbreviationMapper.getTextColor(
                                            dayDto.gorevTamAdi,
                                            isDark: isDark,
                                          ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      dayDto.gorevGruplari.isEmpty
                                          ? dayDto.gorevKodu
                                          : dayDto.gorevGruplari
                                              .take(2)
                                              .map(
                                                (g) =>
                                                    '${DutyAbbreviationMapper.getAbbreviation(g.gorev)}:${g.personelIds.length}',
                                              )
                                              .join('\n'),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            DutyAbbreviationMapper.getTextColor(
                                              dayDto.gorevTamAdi,
                                              isDark: isDark,
                                            ),
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    '-',
                                    style: TextStyle(
                                      color: theme.hintColor,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Seçilen Gün Şık & Kaydırılabilir Detay Paneli
          if (selectedDay != null)
            TeamDutyDayDetails(
              day: selectedDay!,
              monthName: ayAdi,
              year: widget.calendarData.yil,
            ),
        ],
      ),
    );
  }
}
