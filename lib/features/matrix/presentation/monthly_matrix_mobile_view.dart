part of 'monthly_matrix_screen.dart';

extension _MonthlyMatrixMobileView on _MonthlyMatrixScreenState {
  Widget? _buildMonthlyMobileBody({
    required BuildContext context,
    required Map<int?, List<PersonelTableData>> groupedPersonnel,
    required Map<int, String> squadNames,
    required List<PersonelTableData> personnelList,
    required Map<int, Map<int, MatrixDayCell>> matrixData,
    required int daysInMonth,
  }) {
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
                                : context.colorScheme.surfaceContainerHighest
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

    return null;
  }
}
