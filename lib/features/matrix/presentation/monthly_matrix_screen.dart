import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';
import 'package:personelapp2/features/matrix/domain/matrix_personnel_order.dart';
import 'package:personelapp2/features/matrix/presentation/widgets/team_duty_calendar_modal.dart';
import 'package:personelapp2/features/matrix/services/excel_xml_generator.dart';

part 'monthly_matrix_actions.dart';
part 'monthly_matrix_mobile_view.dart';
part 'monthly_matrix_desktop_view.dart';

class MonthlyMatrixScreen extends ConsumerStatefulWidget {
  const MonthlyMatrixScreen({super.key});

  @override
  ConsumerState<MonthlyMatrixScreen> createState() =>
      _MonthlyMatrixScreenState();
}

class _MonthlyMatrixScreenState extends ConsumerState<MonthlyMatrixScreen> {
  DateTime _selectedMonth = DateTime.now();

  // Her bir timin açık/kapalı durumunu takip eden Set (null = timsiz)
  final Set<int?> _expandedTeamIds = {};

  String _getAbbreviation(MatrixDayCell? cell) => cell?.displayCode ?? '-';

  void _updateState(VoidCallback callback) => setState(callback);

  @override
  Widget build(BuildContext context) {
    final yearMonthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final personnelAsync = ref.watch(allPersonnelProvider);
    final squads = ref.watch(allSquadsProvider).valueOrNull ?? const [];
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
              final filteredPersonnel =
                  (session != null && !session.isAdmin && session.timId != null)
                      ? (personnelAsync.value ?? [])
                          .where((p) => p.timId == session.timId)
                          .toList()
                      : (session != null && !session.isAdmin)
                          ? <PersonelTableData>[]
                          : (personnelAsync.value ?? []);
              final personnel = orderMatrixPersonnel(
                filteredPersonnel,
                squads,
              );
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
          final filteredPersonnel = (session != null &&
                  !session.isAdmin &&
                  session.timId != null)
              ? rawPersonnelList.where((p) => p.timId == session.timId).toList()
              : rawPersonnelList;
          final personnelList = orderMatrixPersonnel(
            filteredPersonnel,
            squads,
          );

          if (personnelList.isEmpty) {
            return const Center(
              child: Text('Gösterilecek kayıtlı personel bulunmuyor.'),
            );
          }

          final matrixData = matrixAsync.value ?? {};
          final squadNames = {
            for (final squad in squads) squad.id: squad.timAdi,
          };

          // Personnel'i tim bazlı grupla
          final groupedPersonnel = <int?, List<PersonelTableData>>{};
          for (final person in personnelList) {
            groupedPersonnel.putIfAbsent(person.timId, () => []).add(person);
          }

          final mobileBody = _buildMonthlyMobileBody(
            context: context,
            groupedPersonnel: groupedPersonnel,
            squadNames: squadNames,
            personnelList: personnelList,
            matrixData: matrixData,
            daysInMonth: daysInMonth,
          );
          if (mobileBody != null) return mobileBody;

          return _buildMonthlyDesktopBody(
            context: context,
            groupedPersonnel: groupedPersonnel,
            squadNames: squadNames,
            personnelList: personnelList,
            matrixData: matrixData,
            daysInMonth: daysInMonth,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Hata: $err')),
      ),
    );
  }
}
