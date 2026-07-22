import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/matrix/services/excel_xml_generator.dart';

class MonthlyMatrixScreen extends ConsumerStatefulWidget {
  const MonthlyMatrixScreen({super.key});

  @override
  ConsumerState<MonthlyMatrixScreen> createState() => _MonthlyMatrixScreenState();
}

class _MonthlyMatrixScreenState extends ConsumerState<MonthlyMatrixScreen> {
  DateTime _selectedMonth = DateTime.now();

  Color _getStatusBgColor(String status) {
    if (status.contains('GÖREV') || status.contains('NÖBET')) {
      return AppColors.approvedGreen.withValues(alpha: 0.15);
    } else if (status.contains('İZİN') || status.contains('İSTİRAHAT')) {
      return Colors.grey.shade300;
    } else if (status.contains('RAPOR') || status.contains('SEVK')) {
      return AppColors.rejectedRed.withValues(alpha: 0.15);
    } else if (status.contains('beklemede')) {
      return AppColors.pendingYellow.withValues(alpha: 0.2);
    }
    return Colors.transparent;
  }

  Color _getStatusTextColor(String status) {
    if (status.contains('GÖREV') || status.contains('NÖBET')) {
      return AppColors.approvedGreen;
    } else if (status.contains('İZİN') || status.contains('İSTİRAHAT')) {
      return Colors.black87;
    } else if (status.contains('RAPOR') || status.contains('SEVK')) {
      return AppColors.rejectedRed;
    } else if (status.contains('beklemede')) {
      return Colors.orange.shade900;
    }
    return Colors.black45;
  }

  String _getAbbreviation(String status) {
    if (status.contains('GÖREV')) return 'G';
    if (status.contains('NÖBET')) return 'N';
    if (status.contains('İZİN')) return 'İZ';
    if (status.contains('İSTİRAHAT')) return 'İST';
    if (status.contains('RAPOR')) return 'R';
    if (status.contains('SEVK')) return 'S';
    if (status.contains('beklemede')) return 'B';
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final yearMonthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final personnelAsync = ref.watch(allPersonnelProvider);
    final matrixAsync = ref.watch(monthlyMatrixProvider(yearMonthStr));
    final session = ref.watch(userSessionProvider);

    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Aylık Matris (${DateFormat('MMMM yyyy', 'tr_TR').format(_selectedMonth)})',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Ay Seç',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedMonth = picked);
              }
            },
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
          final personnelList = (session != null && !session.isAdmin && session.timId != null)
              ? rawPersonnelList.where((p) => p.timId == session.timId).toList()
              : rawPersonnelList;

          if (personnelList.isEmpty) {
            return const Center(
              child: Text('Gösterilecek kayıtlı personel bulunmuyor.'),
            );
          }

          final matrixData = matrixAsync.value ?? {};

          return SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sticky Left Column (Personnel Names)
                SizedBox(
                  width: 160,
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        color: AppColors.militaryOlive,
                        alignment: Alignment.center,
                        child: const Text(
                          'Personel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...personnelList.map((p) {
                        return Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                              right: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          child: Text(
                            '${p.rutbe} ${p.adSoyad}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
                          // Days Header Row
                          Container(
                            height: 40,
                            color: AppColors.militaryOlive.withValues(alpha: 0.9),
                            child: Row(
                              children: List.generate(daysInMonth, (index) {
                                return Container(
                                  width: 48,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(color: Colors.white24),
                                    ),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          // Status Grid Rows
                          ...personnelList.map((p) {
                            final pStatusMap = matrixData[p.id] ?? {};

                            return SizedBox(
                              height: 48,
                              child: Row(
                                children: List.generate(daysInMonth, (dIndex) {
                                  final day = dIndex + 1;
                                  final status = pStatusMap[day] ?? '';
                                  final bgColor = _getStatusBgColor(status);
                                  final textColor = _getStatusTextColor(status);
                                  final label = _getAbbreviation(status);

                                  return Container(
                                    width: 48,
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Hata: $err')),
      ),
    );
  }
}
