import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';
import 'package:personelapp2/core/utils/duty_abbreviation_mapper.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;
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
              // Panel Başlığı ve Görev Türü Rozeti
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DutyAbbreviationMapper.getBadgeBgColor(
                        day.gorevTamAdi,
                        isDark: isDark,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      day.gorevKodu.isNotEmpty ? day.gorevKodu : 'SERBEST',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: DutyAbbreviationMapper.getTextColor(
                          day.gorevTamAdi,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.accentOrOlive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${day.gorevliPersonelAdlari.length} Personel',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.accentOrOlive,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Kaydırılabilir Personel Çipleri
              Expanded(
                child: day.gorevliPersonelAdlari.isEmpty
                    ? Center(
                        child: Text(
                          'Bu tarihte görevli personel kaydı bulunmuyor.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: day.gorevliPersonelAdlari
                              .map(
                                (personName) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: context.cardBorderColor,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 14,
                                        color: context.accentOrOlive,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        personName,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
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
