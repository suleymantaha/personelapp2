import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/team_analytics.dart';

class AnalyticsMetricsView extends StatelessWidget {
  const AnalyticsMetricsView({super.key, required this.metrics});
  final AnalyticsMetrics metrics;

  static const List<Color> _metricColors = [
    Color(0xFF4A5D36), // Askeri Haki / Zeytin
    Color(0xFF1D4ED8), // Görev Çeliği / Mavi
    Color(0xFF047857), // Zümrüt Yeşili
    Color(0xFFB45309), // Kehribar / Bronz
    Color(0xFF6D28D9), // Mor / İndigo
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final cardWidth = isNarrow
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth < 960
                ? (constraints.maxWidth - 24) / 3
                : (constraints.maxWidth - 48) / 5;

        final items = [
          (
            'Tim Katılımı',
            metrics.participations,
            Icons.flag_rounded,
            _metricColors[0],
            'En az bir tim personelinin görevlendirildiği faaliyet; tam tim demek değildir'
          ),
          (
            'Görev Günü',
            metrics.dutyDays,
            Icons.calendar_month_rounded,
            _metricColors[1],
            'Görevlendirme bulunan benzersiz takvim günü'
          ),
          (
            'Benzersiz Personel',
            metrics.uniquePersonnel,
            Icons.groups_rounded,
            _metricColors[2],
            'Görev alan kişi sayısı'
          ),
          (
            'Kişi–Görev',
            metrics.personnelTasks,
            Icons.assignment_ind_rounded,
            _metricColors[3],
            'Kişi-faaliyet tekil ataması'
          ),
          (
            'Personel–Gün',
            metrics.personnelDays,
            Icons.event_available_rounded,
            _metricColors[4],
            'Adam-gün toplam yükü'
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: _MetricCard(
                  title: item.$1,
                  value: item.$2,
                  icon: item.$3,
                  accentColor: item.$4,
                  tooltip: item.$5,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.tooltip,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color accentColor;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Card(
        elevation: isDark ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$value',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnalyticsCharts extends StatelessWidget {
  const AnalyticsCharts({super.key, required this.data});
  final TeamAnalytics data;

  static const List<Color> _palette = [
    Color(0xFF4A5D36),
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFFD97706),
    Color(0xFF8B5CF6),
    Color(0xFFDC2626),
    Color(0xFF475569),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalParticipations = data.metrics.participations;
        final dutyRows = [
          for (final duty in data.duties)
            (
              duty,
              data.forDuty(duty).metrics.participations,
              totalParticipations > 0
                  ? (data.forDuty(duty).metrics.participations /
                          totalParticipations *
                          100)
                      .toStringAsFixed(1)
                  : '0.0'
            )
        ];

        final comparison = _dutyComparisonCard(context, dutyRows);
        final trend = _monthlyTrendCard(context, data.monthly);

        if (constraints.maxWidth < 840) {
          return Column(
            children: [
              comparison,
              const SizedBox(height: 16),
              trend,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: comparison),
            const SizedBox(width: 16),
            Expanded(child: trend),
          ],
        );
      },
    );
  }

  Widget _dutyComparisonCard(
    BuildContext context,
    List<(String, int, String)> rows,
  ) {
    final theme = Theme.of(context);
    final max = rows.fold<int>(0, (m, row) => row.$2 > m ? row.$2 : m);

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
                Icon(Icons.pie_chart_outline_rounded,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Görev Karşılaştırması',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Katılım Payı',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Gösterilecek görev verisi yok.')),
              )
            else
              for (var i = 0; i < rows.length; i++) ...[
                _dutyRow(context, rows[i], max, _palette[i % _palette.length]),
                if (i != rows.length - 1) const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  Widget _dutyRow(
    BuildContext context,
    (String, int, String) row,
    int max,
    Color color,
  ) {
    final theme = Theme.of(context);
    final duty = row.$1;
    final count = row.$2;
    final pct = row.$3;
    final ratio = max == 0 ? 0.0 : count / max;

    return Semantics(
      label: '$duty: $count katılım (%$pct)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  duty,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count tim katılımı',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '%$pct',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyTrendCard(
    BuildContext context,
    List<AnalyticsMonth> months,
  ) {
    final theme = Theme.of(context);
    final maxParticipation = months.fold<int>(
        0, (m, item) => item.metrics.participations > m ? item.metrics.participations : m);

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
                Icon(Icons.trending_up_rounded,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aylık Trend',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _legendChip('Tim katılımı', const Color(0xFF4A5D36)),
                const SizedBox(width: 6),
                _legendChip('Gün', const Color(0xFF2563EB)),
              ],
            ),
            const SizedBox(height: 16),
            if (months.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Gösterilecek aylık trend yok.')),
              )
            else
              for (var i = 0; i < months.length; i++) ...[
                _monthRow(context, months[i], maxParticipation),
                if (i != months.length - 1) const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  Widget _legendChip(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _monthRow(
    BuildContext context,
    AnalyticsMonth item,
    int maxParticipation,
  ) {
    final theme = Theme.of(context);
    String monthDisplay;
    try {
      final parts = item.month.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      monthDisplay = DateFormat('MMMM yyyy', 'tr_TR').format(date);
    } catch (_) {
      monthDisplay = item.month;
    }

    final pCount = item.metrics.participations;
    final dCount = item.metrics.dutyDays;
    final ratio = maxParticipation == 0 ? 0.0 : pCount / maxParticipation;

    return Semantics(
      label: '$monthDisplay: $pCount katılım, $dCount gün',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthDisplay,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A5D36).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$pCount k.',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5D36),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$dCount g.',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF4A5D36)),
            ),
          ),
        ],
      ),
    );
  }
}
