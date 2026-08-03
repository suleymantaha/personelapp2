import 'package:flutter/material.dart';
import 'package:personelapp2/core/utils/duty_abbreviation_mapper.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';

class TeamDutyCalendarModal extends StatefulWidget {
  const TeamDutyCalendarModal({
    super.key,
    required this.calendarData,
  });

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

  static const _aylar = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  String _getAyAdi(int month) {
    if (month >= 1 && month <= 12) return _aylar[month];
    return '$month.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ozet = widget.calendarData.ozet;
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
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_month_rounded,
                      color: theme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.calendarData.timAdi} Görev Takvimi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.calendarData.yil} / $ayAdi Ayı Operasyonel Görünüm',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.blue.shade100,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    label: 'Görevli Gün',
                    value: '${ozet.toplamGorevGunSayisi} Gün',
                    icon: Icons.assignment_outlined,
                  ),
                  _buildStatItem(
                    context,
                    label: 'Aktif Personel',
                    value: '${ozet.aktifPersonelSayisi} Kişi',
                    icon: Icons.groups_outlined,
                  ),
                  _buildStatItem(
                    context,
                    label: 'Yoğunluk İndeksi',
                    value: '%${ozet.ortalamaYukYuzdesi.toStringAsFixed(0)}',
                    icon: Icons.speed_rounded,
                    valueColor: ozet.ortalamaYukYuzdesi > 70
                        ? Colors.red
                        : (ozet.ortalamaYukYuzdesi > 40
                            ? Colors.orange
                            : Colors.green),
                  ),
                ],
              ),
            ),
          ),

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
                        'Aylık Günlük Dağılım',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Detaylar için güne tıklayın',
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
                              color: isSelected
                                  ? theme.primaryColor.withValues(alpha: 0.2)
                                  : (hasDuty
                                      ? DutyAbbreviationMapper.getBadgeBgColor(
                                          dayDto.gorevTamAdi,
                                          isDark: isDark,
                                        )
                                      : (isDark
                                          ? Colors.grey.shade900
                                          : Colors.grey.shade100)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor
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
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
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
                                      dayDto.gorevKodu,
                                      style: TextStyle(
                                        fontSize: 11,
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
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.28,
              ),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
                                selectedDay!.gorevTamAdi,
                                isDark: isDark,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedDay!.gorevKodu.isNotEmpty
                                  ? selectedDay!.gorevKodu
                                  : 'SERBEST',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: DutyAbbreviationMapper.getTextColor(
                                  selectedDay!.gorevTamAdi,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${selectedDay!.gunIndex} $ayAdi ${widget.calendarData.yil} • ${selectedDay!.gorevTamAdi}',
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
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${selectedDay!.gorevliPersonelAdlari.length} Personel',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
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
                        child: selectedDay!.gorevliPersonelAdlari.isEmpty
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
                                  children: selectedDay!.gorevliPersonelAdlari
                                      .map(
                                        (personName) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.grey.shade700
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.person_outline_rounded,
                                                size: 14,
                                                color: theme.primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                personName,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
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
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.primaryColor),
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
