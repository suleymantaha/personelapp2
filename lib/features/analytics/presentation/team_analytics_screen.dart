import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';
import '../domain/team_analytics.dart';
import 'analytics_charts.dart';
import 'analytics_details.dart';
import 'team_analytics_provider.dart';
import 'team_monthly_duty_view.dart';

class TeamAnalyticsScreen extends ConsumerStatefulWidget {
  const TeamAnalyticsScreen({
    super.key,
    this.initialFilter,
    this.initialTab = 0,
  });
  final AnalyticsFilter? initialFilter;
  final int initialTab;
  @override
  ConsumerState<TeamAnalyticsScreen> createState() =>
      _TeamAnalyticsScreenState();
}

class _TeamAnalyticsScreenState extends ConsumerState<TeamAnalyticsScreen> {
  late AnalyticsFilter filter;
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 2);
    final now = DateTime.now();
    filter = widget.initialFilter ??
        AnalyticsFilter(
            start: '${now.year}-01-01',
            end: DateFormat('yyyy-MM-dd').format(now));
  }

  void _update({
    int? team,
    String? duty,
    String? status,
    bool clearTeam = false,
    bool clearDuty = false,
  }) =>
      setState(() => filter = AnalyticsFilter(
          start: filter.start,
          end: filter.end,
          teamId: clearTeam ? null : team ?? filter.teamId,
          duty: clearDuty ? null : duty ?? filter.duty,
          status: status ?? filter.status));

  Future<void> _dates() async {
    final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: DateTimeRange(
            start: analyticsDate(filter.start), end: analyticsDate(filter.end)),
        helpText: 'Analiz aralığı · en fazla 366 gün');
    if (selected == null || !mounted) return;
    if (selected.duration.inDays > 365) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En fazla 366 gün seçin.')));
      return;
    }
    setState(() => filter = AnalyticsFilter(
        start: DateFormat('yyyy-MM-dd').format(selected.start),
        end: DateFormat('yyyy-MM-dd').format(selected.end),
        teamId: filter.teamId,
        duty: filter.duty,
        status: filter.status));
  }

  void _setDatePreset(DateTime start, DateTime end) {
    setState(() => filter = AnalyticsFilter(
        start: DateFormat('yyyy-MM-dd').format(start),
        end: DateFormat('yyyy-MM-dd').format(end),
        teamId: filter.teamId,
        duty: filter.duty,
        status: filter.status));
  }

  void _showMethodologyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF4A5D36)),
            SizedBox(width: 10),
            Text('Analiz Metodolojisi'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Salt-Okunur Güvenlik',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              SizedBox(height: 4),
              Text(
                'Bu panel mevcut faaliyet ve atama kayıtlarından salt-okunur snapshot alır; hiçbir veritabanı yazma işlemi yapmaz.',
                style: TextStyle(fontSize: 12.5),
              ),
              Divider(height: 20),
              Text(
                'Hesaplama ve Tekilleştirme Kuralları',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              SizedBox(height: 6),
              Text(
                '• Tim Katılımı: Timden en az bir kişi o faaliyet ve görevdeyse 1 sayılır. Timin tamamının göreve çıktığı anlamına gelmez.\n'
                '• Görev Günü: Kapsanan benzersiz takvim günleridir.\n'
                '• Benzersiz Personel: İlgili dönemde görev alan tekil personel sayısıdır.\n'
                '• Kişi–Görev: Faaliyet ve görev türü başına tekil kişi atamasıdır.\n'
                '• Personel–Gün: Adam-gün toplam iş yüküdür.\n'
                '• Devam Günleri: Önceki günden devam eden görevler yeni katılım oluşturmaz, görev günü üretir.\n'
                '• Hariç Tutulanlar: İzin, istirahat, rapor ve sevk kayıtları operasyonel görev analizi dışında tutulur.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamAnalyticsProvider(filter));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tim Görev Analizi'),
        actions: [
          IconButton(
            tooltip: 'Analiz Metodolojisi',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showMethodologyDialog(context),
          ),
          IconButton(
            tooltip: 'Temayı değiştir',
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: () => ref.read(themeModeProvider.notifier).state =
                Theme.of(context).brightness == Brightness.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
          ),
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(teamAnalyticsProvider(filter)),
          ),
        ],
      ),
      body: TurkishFlagWatermarkBackground(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text('Analiz yüklenemedi.'),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.invalidate(teamAnalyticsProvider(filter)),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
          data: (data) => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _filterCard(context, data),
                  const SizedBox(height: 14),
                  AnalyticsMetricsView(metrics: data.metrics),
                  const SizedBox(height: 14),
                  if (data.unknownTeamAssignments > 0 ||
                      data.duplicateAssignments > 0 ||
                      data.possibleDuplicateActivities > 0)
                    Card(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${data.unknownTeamAssignments} timi bilinmeyen atama · '
                                '${data.duplicateAssignments} tekrarlanan atama tekilleştirildi · '
                                '${data.possibleDuplicateActivities} olası mükerrer faaliyet ayrı tutuldu.',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (data.entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Seçilen filtrelerde görev kaydı yok.'),
                      ),
                    ),
                  _buildTabSelector(context),
                  const SizedBox(height: 14),
                  if (_selectedTab == 0) ...[
                    AnalyticsCharts(data: data),
                  ] else if (_selectedTab == 1) ...[
                    TeamMonthlyDutyView(data: data),
                  ] else ...[
                    AnalyticsDetails(data: data),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabPill(
            index: 0,
            key: const ValueKey('tab-overview'),
            icon: Icons.insights_rounded,
            label: 'Genel Bakış',
          ),
          const SizedBox(width: 8),
          _tabPill(
            index: 1,
            key: const ValueKey('tab-monthly'),
            icon: Icons.calendar_month_rounded,
            label: 'Tim Aylık Görevleri',
          ),
          const SizedBox(width: 8),
          _tabPill(
            index: 2,
            key: const ValueKey('tab-details'),
            icon: Icons.account_tree_outlined,
            label: 'Personel Detayı',
          ),
        ],
      ),
    );
  }

  Widget _tabPill({
    required int index,
    required Key key,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedTab == index;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      key: key,
      color: isSelected
          ? theme.colorScheme.primary
          : (isDark
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterCard(BuildContext context, TeamAnalytics data) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _dates,
                      icon: const Icon(Icons.date_range_rounded, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${filter.start} — ${filter.end}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ActionChip(
                      label: const Text('Bu Ay', style: TextStyle(fontSize: 12)),
                      onPressed: () => _setDatePreset(
                        DateTime(now.year, now.month, 1),
                        now,
                      ),
                    ),
                    ActionChip(
                      label: const Text('Son 3 Ay',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => _setDatePreset(
                        DateTime(now.year, now.month - 2, 1),
                        now,
                      ),
                    ),
                    ActionChip(
                      label:
                          const Text('Bu Yıl', style: TextStyle(fontSize: 12)),
                      onPressed: () => _setDatePreset(
                        DateTime(now.year, 1, 1),
                        now,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDropdowns(context, data, constraints.maxWidth),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdowns(
      BuildContext context, TeamAnalytics data, double maxWidth) {
    final isNarrow = maxWidth < 720;
    final fieldWidth = isNarrow ? maxWidth : (maxWidth - 24) / 3;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: fieldWidth,
          child: DropdownButtonFormField<int>(
            key: ValueKey('team-${filter.teamId}'),
            initialValue: filter.teamId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tim',
              prefixIcon: Icon(Icons.shield_outlined, size: 18),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<int>(
                child: Text('Tüm yetkili timler'),
              ),
              if (filter.teamId != null &&
                  !data.teams.containsKey(filter.teamId))
                DropdownMenuItem(
                  value: filter.teamId,
                  child: const Text('Seçili tim kullanılamıyor'),
                ),
              for (final teamId in data.orderedAvailableTeamIds)
                DropdownMenuItem(
                  value: teamId,
                  child: Text(data.teams[teamId] ?? 'Tim #$teamId'),
                )
            ],
            onChanged: (id) => _update(team: id, clearTeam: id == null),
          ),
        ),
        SizedBox(
          width: fieldWidth,
          child: DropdownButtonFormField<String>(
            key: ValueKey('duty-${filter.duty}'),
            initialValue: filter.duty,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Görev',
              prefixIcon: Icon(Icons.military_tech_outlined, size: 18),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<String>(
                child: Text('Tüm görevler'),
              ),
              for (final duty in {
                ...data.availableDuties,
                if (filter.duty != null) filter.duty!
              })
                DropdownMenuItem(value: duty, child: Text(duty))
            ],
            onChanged: (duty) => _update(duty: duty, clearDuty: duty == null),
          ),
        ),
        SizedBox(
          width: fieldWidth,
          child: DropdownButtonFormField<String>(
            key: const ValueKey('analytics-status'),
            initialValue: filter.status,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Onay durumu',
              prefixIcon: Icon(Icons.verified_outlined, size: 18),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              for (final status in ['onaylandi', 'beklemede', 'reddedildi'])
                DropdownMenuItem(
                  value: status,
                  child: Text(_statusLabel(status)),
                )
            ],
            onChanged: (status) => _update(status: status),
          ),
        ),
      ],
    );
  }

  String _statusLabel(String status) => switch (status) {
        'beklemede' => 'Bekleyen',
        'reddedildi' => 'Reddedilen',
        _ => 'Onaylı',
      };
}
