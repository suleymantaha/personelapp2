import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';
import 'package:personelapp2/features/matrix/domain/matrix_personnel_order.dart';
import 'package:personelapp2/features/matrix/domain/mobile_matrix_list_entry.dart';
import 'package:personelapp2/features/matrix/services/excel_xml_generator.dart';

class MonthlyMatrixScreen extends ConsumerStatefulWidget {
  const MonthlyMatrixScreen({super.key});

  @override
  ConsumerState<MonthlyMatrixScreen> createState() =>
      _MonthlyMatrixScreenState();
}

class _MonthlyMatrixScreenState extends ConsumerState<MonthlyMatrixScreen> {
  DateTime _selectedMonth = DateTime.now();

  String _getAbbreviation(MatrixDayCell? cell) => cell?.displayCode ?? '-';

  String _statusForColor(MatrixDayCell? cell) {
    if (cell == null) return '';
    if (cell.displayCode == 'B') return 'beklemede';
    if (cell.displayCode == 'X') return 'GÖREVLİ';
    return switch (cell.displayCode) {
      'İZ' => 'İZİN',
      'İST' => 'İSTİRAHAT',
      'RAP' => 'RAPOR',
      'SVK' => 'SEVK',
      _ => '',
    };
  }

  Future<void> _showCellDetails(
    BuildContext context,
    PersonelTableData person,
    int day,
    MatrixDayCell cell,
  ) {
    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${person.adSoyad} • ${DateFormat('dd.MM.yyyy').format(date)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...cell.entries.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.activityName),
                  subtitle: Text(
                    '${entry.duty} • Asıl tarih: ${entry.sourceDate}'
                    '${entry.isContinuationDay ? '\nÖnceki günden devam' : ''}',
                  ),
                  trailing: Text(entry.isPending ? 'B' : 'X'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      color: context.accentSubtleBg,
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
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.accentOrOlive,
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
              content: SingleChildScrollView(
                child: SizedBox(
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
                                    ? context.accentOrOlive
                                    : context
                                        .colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? context.accentOrOlive
                                      : context.colorScheme.outlineVariant,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: context.accentOrOlive
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
                                      ? context.onAccentOrOlive
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(tempYear, tempMonth);
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accentOrOlive,
                    foregroundColor: context.onAccentOrOlive,
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
          // Role Filtering: If Commander, only show their squad's personnel
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

          if (context.isMobile) {
            final squadNames = {
              for (final squad in squads) squad.id: squad.timAdi,
            };
            final groupedPersonnel = <int?, List<PersonelTableData>>{};
            for (final person in personnelList) {
              groupedPersonnel.putIfAbsent(person.timId, () => []).add(person);
            }
            final mobileEntries = <MobileMatrixListEntry>[
              for (final group in groupedPersonnel.entries) ...[
                MobileMatrixListEntry.header(
                  group.key == null
                      ? 'Timsiz Personel'
                      : (squadNames[group.key] ?? 'Bilinmeyen Tim'),
                  group.value.length,
                ),
                for (final person in group.value)
                  MobileMatrixListEntry.person(person),
              ],
            ];

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: mobileEntries.length,
              itemBuilder: (context, index) {
                final entry = mobileEntries[index];
                if (entry.isHeader) {
                  return Container(
                    key: ValueKey(
                      'matrix-team-header-${entry.teamName}',
                    ),
                    margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.accentOrOlive,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 20,
                          color: context.onAccentOrOlive,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.teamName!,
                            style: TextStyle(
                              color: context.onAccentOrOlive,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.memberCount} kişi',
                          style: TextStyle(
                            color: context.onAccentOrOlive,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final p = entry.person!;
                final personnelIndex = personnelList.indexOf(p);
                final pStatusMap = matrixData[p.id] ?? {};
                final dutyCount = pStatusMap.values
                    .where((s) => _getAbbreviation(s) == 'X')
                    .length;
                final leaveCount = pStatusMap.values
                    .where(
                      (s) =>
                          _getAbbreviation(s) == 'İZ' ||
                          _getAbbreviation(s) == 'RAP' ||
                          _getAbbreviation(s) == 'İST',
                    )
                    .length;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: context.cardBorderColor,
                    ),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: context.accentOrOlive,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${personnelIndex + 1}',
                        style: TextStyle(
                          color: context.onAccentOrOlive,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      p.adSoyad,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          p.rutbe,
                          style: TextStyle(
                            color: context.accentOrOlive,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (dutyCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Görev: $dutyCount g',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (leaveCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'İzin: $leaveCount g',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 4),
                            Text(
                              'Aylık Çizelge ($daysInMonth Gün):',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: List.generate(daysInMonth, (dIndex) {
                                final day = dIndex + 1;
                                final cell = pStatusMap[day];
                                final status = _statusForColor(cell);
                                final bgColor = context.getStatusBgColor(
                                  status,
                                );
                                final textColor = context.getStatusTextColor(
                                  status,
                                );
                                final label = _getAbbreviation(cell);
                                final isToday = DateTime.now().year ==
                                        _selectedMonth.year &&
                                    DateTime.now().month ==
                                        _selectedMonth.month &&
                                    DateTime.now().day == day;

                                return GestureDetector(
                                  onTap: cell == null
                                      ? null
                                      : () => _showCellDetails(
                                            context,
                                            p,
                                            day,
                                            cell,
                                          ),
                                  child: Container(
                                    width: 42,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: context.cellBorderColor(
                                          isToday: isToday,
                                        ),
                                        width: isToday ? 2.0 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$day',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: textColor.withValues(
                                              alpha: 0.75,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return ResponsiveCenter(
            maxWidth: 1400,
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sticky Left Column (Personnel Rütbe & Name with Sıra No)
                  SizedBox(
                    width: 210,
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
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: context.headerBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    'S.N.',
                                    style: TextStyle(
                                      color: context.onAccentOrOlive,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    'Rütbe',
                                    style: TextStyle(
                                      color: context.onAccentOrOlive,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Adı Soyadı',
                                    style: TextStyle(
                                      color: context.onAccentOrOlive,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
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
                                  color: context.cardBorderColor,
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
                                      color: context.accentOrOlive,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$rowNumber',
                                      style: TextStyle(
                                        color: context.onAccentOrOlive,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Rütbe
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      p.rutbe,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: context.accentOrOlive,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Ad Soyad
                                  Expanded(
                                    child: Text(
                                      p.adSoyad,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                  final isTodayHeader = DateTime.now().year ==
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
                                        color: context.dayHeaderBg(
                                          isToday: isTodayHeader,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$dayNum',
                                        style: TextStyle(
                                          color: context.dayHeaderTextColor(
                                            isToday: isTodayHeader,
                                          ),
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
                                  children: List.generate(daysInMonth, (
                                    dIndex,
                                  ) {
                                    final day = dIndex + 1;
                                    final cell = pStatusMap[day];
                                    final status = _statusForColor(cell);
                                    final bgColor = context.getStatusBgColor(
                                      status,
                                    );
                                    final textColor =
                                        context.getStatusTextColor(status);
                                    final label = _getAbbreviation(cell);

                                    final isToday = DateTime.now().year ==
                                            _selectedMonth.year &&
                                        DateTime.now().month ==
                                            _selectedMonth.month &&
                                        DateTime.now().day == day;

                                    return SizedBox(
                                      width: 48,
                                      child: GestureDetector(
                                        onTap: cell == null
                                            ? null
                                            : () => _showCellDetails(
                                                  context,
                                                  p,
                                                  day,
                                                  cell,
                                                ),
                                        child: Container(
                                          margin: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: context.cellBorderColor(
                                                isToday: isToday,
                                              ),
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
