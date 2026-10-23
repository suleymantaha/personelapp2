import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/providers/providers.dart';
import '../domain/team_analytics.dart';
import 'team_analytics_dates.dart';
import 'team_analytics_filters.dart';
import 'team_analytics_provider.dart';

class TeamAnalyticsSettings extends ConsumerStatefulWidget {
  const TeamAnalyticsSettings(
      {super.key, required this.initialFilter, required this.onChanged});
  final AnalyticsFilter initialFilter;
  final ValueChanged<AnalyticsFilter> onChanged;
  @override
  ConsumerState<TeamAnalyticsSettings> createState() =>
      _TeamAnalyticsSettingsState();
}

class _TeamAnalyticsSettingsState extends ConsumerState<TeamAnalyticsSettings> {
  late AnalyticsFilter filter = widget.initialFilter;
  bool expanded = true;

  void _change(AnalyticsFilter value) {
    setState(() => filter = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamAnalyticsProvider(filter));
    return FractionallySizedBox(
      heightFactor: .88,
      child: Column(children: [
        ListTile(
          title: const Text('Analiz ayarları'),
          trailing: IconButton(
              key: const ValueKey('analytics-settings-close'),
              tooltip: 'Kapat',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close)),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TeamAnalyticsDates(filter: filter, onChanged: _change),
            const Divider(),
            async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Text('Filtreler yüklenemedi.'),
              data: (data) => TeamAnalyticsFilters(
                  data: data,
                  onChanged: _change,
                  expanded: expanded,
                  onToggle: () => setState(() => expanded = !expanded)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Analiz Metodolojisi'),
              onTap: () => showAnalyticsMethodology(context),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('Temayı değiştir'),
              onTap: () => ref.read(themeModeProvider.notifier).state =
                  Theme.of(context).brightness == Brightness.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
            ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Yenile'),
              onTap: () => ref.invalidate(teamAnalyticsProvider(filter)),
            ),
          ]),
        ),
      ]),
    );
  }
}

void showAnalyticsMethodology(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
          title: const Text('Görev kayıtları nasıl sayılır?'),
          content: const SingleChildScrollView(
              child: Text(
                  'Her tim seçilen tarihte bir kez listelenir. Kişi sayıları tekil personeldir. '
                  'Her faaliyet ve görev ayrı bir görev kaydıdır; matriste birden fazla '
                  'güne işaretlenmesi yeni kayıt oluşturmaz. Önceki günden devam eden '
                  'görevin başlangıç tarihi detayda korunur. Bir kişinin katılımı tüm timin '
                  'görevlendirildiği anlamına gelmez. Bu ekran kayıtları değiştirmez.')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'))
          ],
        ));
