import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../analytics/domain/team_analytics.dart';
import '../../analytics/presentation/team_analytics_provider.dart';
import '../domain/watch_roster.dart';
import 'watch_roster_days.dart';

class WatchRosterScreen extends ConsumerStatefulWidget {
  const WatchRosterScreen({super.key, this.initialMonth});
  final DateTime? initialMonth;
  @override
  ConsumerState<WatchRosterScreen> createState() => _WatchRosterScreenState();
}

class _WatchRosterScreenState extends ConsumerState<WatchRosterScreen> {
  late DateTime _month;
  static const months = [
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
    'Aralık'
  ];
  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth ?? DateTime.now();
    _month = DateTime(initial.year, initial.month);
  }

  Future<void> _chooseMonth() async {
    var year = _month.year;
    var month = _month.month;
    final chosen = await showDialog<DateTime>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: const Text('Ay seç'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                                tooltip: 'Önceki yıl',
                                onPressed: year > 1900
                                    ? () => update(() => year--)
                                    : null,
                                icon: const Icon(Icons.chevron_left)),
                            Text('$year'),
                            IconButton(
                                tooltip: 'Sonraki yıl',
                                onPressed: year < 9998
                                    ? () => update(() => year++)
                                    : null,
                                icon: const Icon(Icons.chevron_right)),
                          ]),
                      DropdownButton<int>(
                          value: month,
                          isExpanded: true,
                          items: [
                            for (var i = 1; i <= 12; i++)
                              DropdownMenuItem(
                                  value: i, child: Text(months[i - 1]))
                          ],
                          onChanged: (value) => update(() => month = value!)),
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal')),
                      FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, DateTime(year, month)),
                          child: const Text('Seç')),
                    ])));
    if (chosen != null && mounted) setState(() => _month = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final filter = AnalyticsFilter(
        start: _month.toIso8601String().substring(0, 10),
        end: DateTime(_month.year, _month.month + 1, 0)
            .toIso8601String()
            .substring(0, 10));
    final data = ref.watch(teamAnalyticsProvider(filter));
    return Scaffold(
        appBar: AppBar(title: const Text('NÖBET')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                IconButton(
                    key: const ValueKey('watch-previous-month'),
                    tooltip: 'Önceki ay',
                    onPressed: _month.year <= 1900 && _month.month == 1
                        ? null
                        : () => setState(() =>
                            _month = DateTime(_month.year, _month.month - 1)),
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                    child: TextButton(
                        key: const ValueKey('watch-select-month'),
                        onPressed: _chooseMonth,
                        child: Text(
                            '${months[_month.month - 1]} ${_month.year}',
                            textAlign: TextAlign.center))),
                IconButton(
                    key: const ValueKey('watch-next-month'),
                    tooltip: 'Sonraki ay',
                    onPressed: _month.year >= 9998 && _month.month == 12
                        ? null
                        : () => setState(() =>
                            _month = DateTime(_month.year, _month.month + 1)),
                    icon: const Icon(Icons.chevron_right)),
              ])),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Nöbet başlangıç tarihine göre onaylı kayıtlar. '
                  'Personeli görmek için takvimden bir gün seçin.')),
          Expanded(
              child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Nöbet kayıtları yüklenemedi.'),
              TextButton(
                  onPressed: () =>
                      ref.invalidate(teamAnalyticsProvider(filter)),
                  child: const Text('Tekrar dene')),
            ]))),
            data: (value) =>
                WatchRosterDays(month: _month, roster: WatchRoster(value)),
          )),
        ]));
  }
}
