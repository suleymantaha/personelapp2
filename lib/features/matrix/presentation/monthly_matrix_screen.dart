import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/features/matrix/services/excel_xml_generator.dart';

class MonthlyMatrixScreen extends ConsumerStatefulWidget {
  const MonthlyMatrixScreen({super.key});

  @override
  ConsumerState<MonthlyMatrixScreen> createState() =>
      _MonthlyMatrixScreenState();
}

class _MonthlyMatrixScreenState extends ConsumerState<MonthlyMatrixScreen> {
  DateTime _selectedMonth = DateTime.now();

  Color _getStatusBgColor(String status, BuildContext context) {
    final isDark = context.isDarkMode;
    if (status.contains('GÖREV') || status.contains('NÖBET')) {
      return isDark ? AppColors.statusDutyDark : AppColors.statusDutyLight;
    } else if (status.contains('İZİN') || status.contains('İSTİRAHAT')) {
      return isDark ? AppColors.statusLeaveDark : AppColors.statusLeaveLight;
    } else if (status.contains('RAPOR') || status.contains('SEVK')) {
      return isDark ? AppColors.statusReportDark : AppColors.statusReportLight;
    } else if (status.contains('beklemede')) {
      return isDark ? AppColors.statusPendingDark : AppColors.statusPendingLight;
    }
    return isDark ? AppColors.cardDark : Colors.transparent;
  }

  Color _getStatusTextColor(String status, BuildContext context) {
    final isDark = context.isDarkMode;
    if (status.contains('GÖREV') || status.contains('NÖBET')) {
      return isDark ? AppColors.statusDutyTextDark : AppColors.statusDutyTextLight;
    } else if (status.contains('İZİN') || status.contains('İSTİRAHAT')) {
      return isDark ? AppColors.statusLeaveTextDark : AppColors.statusLeaveTextLight;
    } else if (status.contains('RAPOR') || status.contains('SEVK')) {
      return isDark ? AppColors.statusReportTextDark : AppColors.statusReportTextLight;
    } else if (status.contains('beklemede')) {
      return isDark ? AppColors.statusPendingTextDark : AppColors.statusPendingTextLight;
    }
    return context.textMuted;
  }

  String _getAbbreviation(String status) {
    if (status.contains('GÖREV') ||
        status.contains('NÖBET') ||
        status.contains('HAZIR KITA') ||
        status.contains('GÜLÜŞKÜR') ||
        status.contains('HEYBET')) {
      return 'X';
    }
    if (status.contains('İZİN')) return 'İZ';
    if (status.contains('İSTİRAHAT')) return 'İST';
    if (status.contains('RAPOR')) return 'RAP';
    if (status.contains('SEVK')) return 'SVK';
    if (status.contains('beklemede')) return 'B';
    return '-';
  }

  Future<void> _selectMonthYear(BuildContext context) async {
    var tempYear = _selectedMonth.year;
    var tempMonth = _selectedMonth.month;

    final months = [
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

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tarih Seçin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.militaryOlive.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: () => setDialogState(() => tempYear--),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '$tempYear',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.militaryOlive,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: () => setDialogState(() => tempYear++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final isSelected = (index + 1) == tempMonth;
                        return InkWell(
                          onTap: () {
                            setDialogState(() => tempMonth = index + 1);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.militaryOlive
                                  : context.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.militaryOlive
                                    : context.colorScheme.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.militaryOlive
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              months[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : context.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(tempYear, tempMonth, 1);
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.militaryOlive,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final yearMonthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final personnelAsync = ref.watch(allPersonnelProvider);
    final matrixAsync = ref.watch(monthlyMatrixProvider(yearMonthStr));
    final session = ref.watch(userSessionProvider);

    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _selectMonthYear(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('MMMM yyyy', 'tr_TR').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Önceki Ay',
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                  1,
                );
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Sonraki Ay',
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                  1,
                );
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Ay/Yıl Seç',
            onPressed: () => _selectMonthYear(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: "Excel'e Aktar",
            onPressed: () {
              final personnel = personnelAsync.value ?? [];
              final matrixData = matrixAsync.value ?? {};
              if (personnel.isEmpty) return;

              unawaited(
                ExcelXmlGenerator.exportAndShareXml(
                  personnel: personnel,
                  matrixData: matrixData,
                  year: _selectedMonth.year,
                  month: _selectedMonth.month,
                ),
              );
            },
          ),
        ],
      ),
      body: personnelAsync.when(
        data: (rawPersonnelList) {
          // Role Filtering: If Commander, only show their squad's personnel
          final personnelList =
              (session != null && !session.isAdmin && session.timId != null)
              ? rawPersonnelList.where((p) => p.timId == session.timId).toList()
              : rawPersonnelList;

          if (personnelList.isEmpty) {
            return const Center(
              child: Text('Gösterilecek kayıtlı personel bulunmuyor.'),
            );
          }

          final matrixData = matrixAsync.value ?? {};

          return ResponsiveCenter(
            maxWidth: 1400,
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sticky Left Column (Personnel Names with Sıra No)
                SizedBox(
                  width: 165,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Personnel Header Cell (Height 48 to match Days Header)
                      SizedBox(
                        height: 48,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.militaryOlive,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'S.N. | Personel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      // Personnel Data Rows (Bounded Rounded Boxes matching status grid)
                      ...personnelList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final p = entry.value;
                        final rowNumber = index + 1;

                        return SizedBox(
                          height: 48,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.militaryOlive.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Sıra No Badge
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: AppColors.militaryOlive,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$rowNumber',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Rank & Name
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.adSoyad,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        p.rutbe,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.militaryOlive,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Horizontally Scrollable Days Grid (1 to 31)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: daysInMonth * 48.0,
                      child: Column(
                        children: [
                          // Days Header Row (Height 48 to match Personnel Header)
                          SizedBox(
                            height: 48,
                            child: Row(
                              children: List.generate(daysInMonth, (index) {
                                final dayNum = index + 1;
                                final isTodayHeader =
                                    DateTime.now().year ==
                                        _selectedMonth.year &&
                                    DateTime.now().month ==
                                        _selectedMonth.month &&
                                    DateTime.now().day == dayNum;

                                return SizedBox(
                                  width: 48,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isTodayHeader
                                          ? Colors.amber.shade700
                                          : AppColors.darkOlive,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$dayNum',
                                      style: TextStyle(
                                        color: isTodayHeader
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          // Status Grid Rows
                          ...personnelList.asMap().entries.map((entry) {
                            final p = entry.value;
                            final pStatusMap = matrixData[p.id] ?? {};

                            return SizedBox(
                              height: 48,
                              child: Row(
                                children: List.generate(daysInMonth, (dIndex) {
                                  final day = dIndex + 1;
                                  final status = pStatusMap[day] ?? '';
                                  final bgColor = _getStatusBgColor(status, context);
                                  final textColor = _getStatusTextColor(status, context);
                                  final label = _getAbbreviation(status);

                                  final isToday =
                                      DateTime.now().year ==
                                          _selectedMonth.year &&
                                      DateTime.now().month ==
                                          _selectedMonth.month &&
                                      DateTime.now().day == day;

                                  return SizedBox(
                                    width: 48,
                                    child: Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isToday
                                              ? AppColors.militaryOlive
                                              : AppColors.militaryOlive
                                                    .withValues(alpha: 0.35),
                                          width: isToday ? 2.0 : 1.2,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Hata: $err')),
      ),
    );
  }
}
