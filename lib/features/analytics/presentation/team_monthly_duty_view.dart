import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/team_analytics.dart';

class TeamMonthlyDutyView extends StatelessWidget {
  const TeamMonthlyDutyView({super.key, required this.data});
  final TeamAnalytics data;

  static const List<Color> _dutyPalette = [
    Color(0xFF4A5D36),
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFFD97706),
    Color(0xFF8B5CF6),
    Color(0xFFDC2626),
    Color(0xFF0284C7),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Seçilen filtrelerde aylık tim görev kaydı bulunamadı.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    final teamIds = data.entries
        .map((e) => e.teamId)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort((a, b) => (data.teams[a] ?? '').compareTo(data.teams[b] ?? ''));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBalanceOverviewCard(context, teamIds),
        const SizedBox(height: 16),
        _buildMonthlyBreakdownCard(context, teamIds),
      ],
    );
  }

  /// Timler arası görev yükü ve katılım dağılımı denge kartı
  Widget _buildBalanceOverviewCard(BuildContext context, List<int> teamIds) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.balance_rounded,
                      color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timler Arası Görev Denge Analizi',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Seçili dönemde timlerin üstlendiği toplam görev ve gün yükü',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final teamId in teamIds) ...[
              _buildTeamBalanceRow(context, teamId, isDark),
              if (teamId != teamIds.last) const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBalanceRow(BuildContext context, int teamId, bool isDark) {
    final theme = Theme.of(context);
    final teamSlice = data.forTeam(teamId);
    final teamName = data.teams[teamId] ?? 'Tim #$teamId';
    final metrics = teamSlice.metrics;

    // Görev türü dağılımı
    final dutyCounts = <String, int>{};
    for (final duty in teamSlice.duties) {
      dutyCounts[duty] = teamSlice.forDuty(duty).metrics.participations;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                teamName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Text(
              '${metrics.participations} Katılım',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              '${metrics.dutyDays} Gün',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: const Color(0xFF2563EB),
              ),
            ),
            Text(
              '${metrics.uniquePersonnel} Personel',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < dutyCounts.entries.length; i++) ...[
              _dutyBadge(
                dutyCounts.entries.elementAt(i).key,
                dutyCounts.entries.elementAt(i).value,
                _dutyPalette[i % _dutyPalette.length],
                isDark,
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Ay ay timlerin görev detay dökümü
  Widget _buildMonthlyBreakdownCard(
      BuildContext context, List<int> teamIds) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Ayları sondan başa sırala (en güncel ay en üstte)
    final months = data.monthly.reversed.toList();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.date_range_rounded,
                      color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aylık Tim Görev Dağılım Tablosu',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Her ay gerçekleştirilen görevlerin tim bazlı dökümü',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final monthItem in months) ...[
              _buildMonthSection(context, monthItem, teamIds, isDark),
              if (monthItem != months.last) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSection(
    BuildContext context,
    AnalyticsMonth monthItem,
    List<int> teamIds,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    String monthDisplay;
    try {
      final parts = monthItem.month.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      monthDisplay = DateFormat('MMMM yyyy', 'tr_TR').format(date);
    } catch (_) {
      monthDisplay = monthItem.month;
    }

    final monthStart = '${monthItem.month}-01';
    final monthParts = monthItem.month.split('-');
    final lastDay =
        DateTime(int.parse(monthParts[0]), int.parse(monthParts[1]) + 1, 0).day;
    final monthEnd =
        '${monthItem.month}-${lastDay.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthDisplay,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A5D36).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${monthItem.metrics.participations} Katılım',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5D36),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${monthItem.metrics.dutyDays} Gün',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // O aydaki timlerin karnesi
          for (final teamId in teamIds) ...[
            _buildTeamMonthRow(
              context,
              teamId,
              monthStart,
              monthEnd,
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamMonthRow(
    BuildContext context,
    int teamId,
    String monthStart,
    String monthEnd,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final teamName = data.teams[teamId] ?? 'Tim #$teamId';

    // O ayda bu timin girdileri
    final teamEntriesInMonth = data.entries.where((e) {
      if (e.teamId != teamId) return false;
      return e.coveredDates
          .any((d) => d.compareTo(monthStart) >= 0 && d.compareTo(monthEnd) <= 0);
    }).toList();

    if (teamEntriesInMonth.isEmpty) {
      return const SizedBox.shrink();
    }

    final teamMonthMetrics =
        AnalyticsMetrics(teamEntriesInMonth, monthStart, monthEnd);

    // Görev türlerine göre say
    final dutyCounts = <String, int>{};
    for (final e in teamEntriesInMonth) {
      if (e.sourceDate.compareTo(monthStart) >= 0 &&
          e.sourceDate.compareTo(monthEnd) <= 0) {
        dutyCounts[e.duty] = (dutyCounts[e.duty] ?? 0) + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      teamName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '${teamMonthMetrics.participations} Katılım · ${teamMonthMetrics.dutyDays} Gün',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (var i = 0; i < dutyCounts.entries.length; i++)
                  _dutyBadge(
                    dutyCounts.entries.elementAt(i).key,
                    dutyCounts.entries.elementAt(i).value,
                    _dutyPalette[i % _dutyPalette.length],
                    isDark,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dutyBadge(String duty, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            duty,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}
