part of 'monthly_matrix_screen.dart';

extension _MonthlyMatrixActions on _MonthlyMatrixScreenState {
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
                    _updateState(() {
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
}
