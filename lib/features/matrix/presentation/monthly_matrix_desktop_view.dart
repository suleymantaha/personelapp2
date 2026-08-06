part of 'monthly_matrix_screen.dart';

extension _MonthlyMatrixDesktopView on _MonthlyMatrixScreenState {
  Widget _buildMonthlyDesktopBody({
    required BuildContext context,
    required Map<int?, List<PersonelTableData>> groupedPersonnel,
    required Map<int, String> squadNames,
    required List<PersonelTableData> personnelList,
    required Map<int, Map<int, MatrixDayCell>> matrixData,
    required int daysInMonth,
  }) {
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
                    _updateState(() {
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
                            color:
                                context.onAccentOrOlive.withValues(alpha: 0.2),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                      SizedBox(
                                        width: 36,
                                        child: Text(
                                          'Top.',
                                          textAlign: TextAlign.center,
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
                                      borderRadius: BorderRadius.circular(6),
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
                                              color: context.onAccentOrOlive,
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
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: context.accentOrOlive,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
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
                                        Container(
                                          width: 32,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: dutyCount > 0
                                                ? context.accentOrOlive
                                                    .withValues(alpha: 0.15)
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
                                              color: context.accentOrOlive,
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
                                      children:
                                          List.generate(daysInMonth, (dIdx) {
                                        final dayNum = dIdx + 1;
                                        final isTodayHeader =
                                            DateTime.now().year ==
                                                    _selectedMonth.year &&
                                                DateTime.now().month ==
                                                    _selectedMonth.month &&
                                                DateTime.now().day == dayNum;

                                        return SizedBox(
                                          width: 44,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
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
                                                color:
                                                    context.dayHeaderTextColor(
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
                                  ...members.map((p) {
                                    final pStatusMap = matrixData[p.id] ?? {};

                                    return SizedBox(
                                      height: 44,
                                      child: Row(
                                        children: List.generate(daysInMonth,
                                            (dIndex) {
                                          final day = dIndex + 1;
                                          final cell = pStatusMap[day];
                                          final status = _statusForColor(cell);
                                          final bgColor =
                                              context.getStatusBgColor(status);
                                          final textColor = context
                                              .getStatusTextColor(status);
                                          final label = _getAbbreviation(cell);

                                          final isToday = DateTime.now().year ==
                                                  _selectedMonth.year &&
                                              DateTime.now().month ==
                                                  _selectedMonth.month &&
                                              DateTime.now().day == day;

                                          return SizedBox(
                                            width: 44,
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
                                                margin: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: bgColor,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color:
                                                        context.cellBorderColor(
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
  }
}
