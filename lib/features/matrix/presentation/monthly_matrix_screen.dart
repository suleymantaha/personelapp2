import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/matrix/services/excel_xml_generator.dart';

class MonthlyMatrixScreen extends ConsumerStatefulWidget {
  const MonthlyMatrixScreen({super.key});

  @override
  ConsumerState<MonthlyMatrixScreen> createState() => _MonthlyMatrixScreenState();
}

class _MonthlyMatrixScreenState extends ConsumerState<MonthlyMatrixScreen> {
  final DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final personnelAsync = ref.watch(allPersonnelProvider);
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Aylık Matris (${DateFormat('MMMM yyyy', 'tr_TR').format(_selectedMonth)})',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: "Excel'e Aktar",
            onPressed: () {
              final personnel = personnelAsync.value ?? [];
              if (personnel.isEmpty) return;

              ExcelXmlGenerator.exportAndShareXml(
                personnel: personnel,
                matrixData: {},
                year: _selectedMonth.year,
                month: _selectedMonth.month,
              );
            },
          ),
        ],
      ),
      body: personnelAsync.when(
        data: (personnelList) {
          if (personnelList.isEmpty) {
            return const Center(
              child: Text('Matris oluşturmak için önce personel ekleyiniz.'),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
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
                            return SizedBox(
                              height: 48,
                              child: Row(
                                children: List.generate(daysInMonth, (dIndex) {
                                  return Container(
                                    width: 48,
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppColors.approvedGreen
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'G',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.approvedGreen,
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
