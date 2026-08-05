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

  Future<void> _showTeamCalendarModal(
    BuildContext context,
    int? timId,
    String timAdi,
  ) async {
    if (timId == null) return;
    final repository = ref.read(matrixRepositoryProvider);
    final calendarData = await repository.getTeamMonthlyCalendar(
      timId: timId,
      timAdi: timAdi,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );
    if (!context.mounted) return;
    await TeamDutyCalendarModal.show(
      context,
      calendarData: calendarData,
    );
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

  Widget _buildMobileCalendar({
    required BuildContext context,
    required PersonelTableData person,
    required Map<int, MatrixDayCell> statusByDay,
    required int daysInMonth,
  }) {
    const weekdayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final leadingEmptyCells =
        DateTime(_selectedMonth.year, _selectedMonth.month).weekday - 1;
    final cellCount = ((leadingEmptyCells + daysInMonth + 6) ~/ 7) * 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellExtent = (constraints.maxWidth - 36) / 7;
        return Column(
          key: const ValueKey('monthly-calendar-grid'),
          children: [
            Row(
              children: weekdayLabels
                  .map(
                    (label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cellCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                mainAxisExtent: cellExtent.clamp(34, 46),
              ),
              itemBuilder: (context, index) {
                final day = index - leadingEmptyCells + 1;
                if (day < 1 || day > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final cell = statusByDay[day];
                final status = _statusForColor(cell);
                final label = _getAbbreviation(cell);
                final isToday = DateTime.now().year == _selectedMonth.year &&
                    DateTime.now().month == _selectedMonth.month &&
                    DateTime.now().day == day;
                final hasStatus = cell != null;
                final textColor = context.getStatusTextColor(status);

                return Semantics(
                  button: hasStatus,
                  label: '$day. gün${hasStatus ? ', $label' : ', boş'}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: cell == null
                        ? null
                        : () => _showCellDetails(context, person, day, cell),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: hasStatus
                            ? context.getStatusBgColor(status)
                            : context.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.cellBorderColor(isToday: isToday),
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color: hasStatus ? textColor : context.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (hasStatus)
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
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

          // Mobil Ekran Tasarımı (Varsayılan Kapalı Tim Akordeon Kartları)
          if (context.isMobile) {
            return ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.compactPagePadding,
              ),
              children: groupedPersonnel.entries.map((group) {
                final teamId = group.key;
                final teamName = teamId == null
                    ? 'Timsiz Personel'
                    : (squadNames[teamId] ?? 'Bilinmeyen Tim');
                final members = group.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.cardBorderColor),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: false, // Varsayılan KAPALI!
                    minTileHeight: 76,
                    tilePadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                    childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    collapsedBackgroundColor: context.accentSubtleBg,
                    backgroundColor: context.accentSubtleBg,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Icon(
                      Icons.groups_rounded,
                      color: context.accentOrOlive,
                    ),
                    title: Text(
                      teamName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${members.length} Personel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (teamId != null)
                          IconButton(
                            icon: Icon(
                              Icons.calendar_month_outlined,
                              color: context.accentOrOlive,
                            ),
                            tooltip: 'Görev Takvimi',
                            onPressed: () => _showTeamCalendarModal(
                              context,
                              teamId,
                              teamName,
                            ),
                          ),
                        const Icon(Icons.expand_more_rounded),
                      ],
                    ),
                    children: members.map((p) {
                      final personnelIndex = personnelList.indexOf(p);
                      final pStatusMap = matrixData[p.id] ?? {};
                      final dutyCount = pStatusMap.values
                          .where(
                            (s) =>
                                _getAbbreviation(s) != '-' &&
                                _getAbbreviation(s) != 'İZ' &&
                                _getAbbreviation(s) != 'RAP' &&
                                _getAbbreviation(s) != 'İST' &&
                                _getAbbreviation(s) != 'SVK',
                          )
                          .length;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          key: ValueKey('personnel-${p.id}'),
                          minTileHeight: 70,
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          childrenPadding: EdgeInsets.zero,
                          shape: Border(
                            left: BorderSide(
                              color: context.accentOrOlive,
                              width: 4,
                            ),
                          ),
                          collapsedShape: const Border(),
                          leading: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: context.accentOrOlive,
                              borderRadius: BorderRadius.circular(9),
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
                              Expanded(
                                child: Text(
                                  p.rutbe,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: dutyCount > 0
                                      ? context.accentSubtleBg
                                      : context
                                          .colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$dutyCount gün',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: dutyCount > 0
                                        ? context.accentOrOlive
                                        : context.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(color: context.cardBorderColor),
                                  Text(
                                    'Aylık çizelge · $daysInMonth gün',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildMobileCalendar(
                                    context: context,
                                    person: p,
                                    statusByDay: pStatusMap,
                                    daysInMonth: daysInMonth,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            );
          }

          // Masaüstü / Tablet Ekran Tasarımı (Varsayılan Kapalı Tim Akordeon Gridi)
          return ResponsiveCenter(
            maxWidth: 1400,
            padding: EdgeInsets.zero,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.compactPagePadding),
              children: groupedPersonnel.entries.map((group) {
                final teamId = group.key;
                final teamName = teamId == null
                    ? 'Timsiz Personel'
                    : (squadNames[teamId] ?? 'Bilinmeyen Tim');
                final members = group.value;
                final isExpanded = _expandedTeamIds.contains(teamId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: context.cardBorderColor),
                  ),
                  child: Column(
                    children: [
                      // Tim Başlık Şeridi (Tıklanınca açılır/kapanır)
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedTeamIds.remove(teamId);
                            } else {
                              _expandedTeamIds.add(teamId);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: context.accentOrOlive,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_right_rounded,
                                color: context.onAccentOrOlive,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.groups_rounded,
                                color: context.onAccentOrOlive,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                teamName,
                                style: TextStyle(
                                  color: context.onAccentOrOlive,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.onAccentOrOlive
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${members.length} Personel',
                                  style: TextStyle(
                                    color: context.onAccentOrOlive,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (teamId != null)
                                ElevatedButton.icon(
                                  onPressed: () => _showTeamCalendarModal(
                                    context,
                                    teamId,
                                    teamName,
                                  ),
                                  icon: const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Görev Takvimi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.onAccentOrOlive,
                                    foregroundColor: context.accentOrOlive,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Tim Açıldığında Gösterilecek 31 Günlük Matris Tablosu
                      if (isExpanded)
                        SingleChildScrollView(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sticky Left Personnel Column
                              SizedBox(
                                width: 260,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Table Header Cell
                                    SizedBox(
                                      height: 44,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                          vertical: 2,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.headerBg,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              child: Text(
                                                'S.N.',
                                                style: TextStyle(
                                                  color:
                                                      context.onAccentOrOlive,
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
                                                  color:
                                                      context.onAccentOrOlive,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                'Adı Soyadı',
                                                style: TextStyle(
                                                  color:
                                                      context.onAccentOrOlive,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 36,
                                              child: Text(
                                                'Top.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color:
                                                      context.onAccentOrOlive,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Personnel Rows
                                    ...members.asMap().entries.map((mEntry) {
                                      final index = mEntry.key;
                                      final p = mEntry.value;
                                      final rowNumber = index + 1;
                                      final pStatusMap = matrixData[p.id] ?? {};
                                      final dutyCount = pStatusMap.values
                                          .where(
                                            (s) =>
                                                _getAbbreviation(s) != '-' &&
                                                _getAbbreviation(s) != 'İZ' &&
                                                _getAbbreviation(s) != 'RAP' &&
                                                _getAbbreviation(s) != 'İST' &&
                                                _getAbbreviation(s) != 'SVK',
                                          )
                                          .length;

                                      return SizedBox(
                                        height: 44,
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
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: context.cardBorderColor,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: context.accentOrOlive,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '$rowNumber',
                                                  style: TextStyle(
                                                    color:
                                                        context.onAccentOrOlive,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              SizedBox(
                                                width: 60,
                                                child: Text(
                                                  p.rutbe,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        context.accentOrOlive,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  p.adSoyad,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 32,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: dutyCount > 0
                                                      ? context.accentOrOlive
                                                          .withValues(
                                                              alpha: 0.15)
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '$dutyCount',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        context.accentOrOlive,
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

                              // Days Grid Column (1 to 31)
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: daysInMonth * 44.0,
                                    child: Column(
                                      children: [
                                        // Header Row
                                        SizedBox(
                                          height: 44,
                                          child: Row(
                                            children: List.generate(daysInMonth,
                                                (dIdx) {
                                              final dayNum = dIdx + 1;
                                              final isTodayHeader =
                                                  DateTime.now().year ==
                                                          _selectedMonth.year &&
                                                      DateTime.now().month ==
                                                          _selectedMonth
                                                              .month &&
                                                      DateTime.now().day ==
                                                          dayNum;

                                              return SizedBox(
                                                width: 44,
                                                child: Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 2,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: context.dayHeaderBg(
                                                      isToday: isTodayHeader,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      6,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '$dayNum',
                                                    style: TextStyle(
                                                      color: context
                                                          .dayHeaderTextColor(
                                                        isToday: isTodayHeader,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),

                                        // Status Grid Rows
                                        ...members.map((p) {
                                          final pStatusMap =
                                              matrixData[p.id] ?? {};

                                          return SizedBox(
                                            height: 44,
                                            child: Row(
                                              children: List.generate(
                                                  daysInMonth, (dIndex) {
                                                final day = dIndex + 1;
                                                final cell = pStatusMap[day];
                                                final status =
                                                    _statusForColor(cell);
                                                final bgColor = context
                                                    .getStatusBgColor(status);
                                                final textColor = context
                                                    .getStatusTextColor(status);
                                                final label =
                                                    _getAbbreviation(cell);

                                                final isToday = DateTime.now()
                                                            .year ==
                                                        _selectedMonth.year &&
                                                    DateTime.now().month ==
                                                        _selectedMonth.month &&
                                                    DateTime.now().day == day;

                                                return SizedBox(
                                                  width: 44,
                                                  child: GestureDetector(
                                                    onTap: cell == null
                                                        ? null
                                                        : () =>
                                                            _showCellDetails(
                                                              context,
                                                              p,
                                                              day,
                                                              cell,
                                                            ),
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                        2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: bgColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                        border: Border.all(
                                                          color: context
                                                              .cellBorderColor(
                                                            isToday: isToday,
                                                          ),
                                                          width: isToday
                                                              ? 2.0
                                                              : 1.2,
                                                        ),
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        label,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
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
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Hata: $err')),
      ),
    );
  }
}
