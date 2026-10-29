import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../activity/services/roster_share_file.dart';
import '../domain/monthly_analytics_report.dart';
import '../domain/team_analytics.dart';
import '../services/monthly_analytics_excel_exporter.dart';
import 'monthly_daily_chart.dart';
import 'monthly_report_sections.dart';
import 'monthly_period_selector.dart';
import 'monthly_personnel_summary.dart';

class MonthlyAnalyticsView extends StatefulWidget {
  const MonthlyAnalyticsView(
      {super.key,
      required this.data,
      this.asOf,
      this.onFilterChanged,
      this.onExport});
  final TeamAnalytics data;
  final DateTime? asOf;
  final ValueChanged<AnalyticsFilter>? onFilterChanged;
  final Future<void> Function(MonthlyAnalyticsReport)? onExport;
  @override
  State<MonthlyAnalyticsView> createState() => _MonthlyAnalyticsViewState();
}

class _MonthlyAnalyticsViewState extends State<MonthlyAnalyticsView> {
  late MonthlyAnalyticsReport report;
  bool exporting = false;
  @override
  void initState() {
    super.initState();
    _buildReport();
  }

  void _buildReport() => report = MonthlyAnalyticsReport(
      data: widget.data, asOf: widget.asOf ?? DateTime.now());
  @override
  void didUpdateWidget(covariant MonthlyAnalyticsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data) ||
        oldWidget.asOf != widget.asOf) {
      _buildReport();
    }
  }

  Future<void> _export() async {
    if (exporting) return;
    final snapshot = report;
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    setState(() => exporting = true);
    try {
      if (widget.onExport case final callback?) {
        await callback(snapshot);
      } else {
        final bytes = MonthlyAnalyticsExcelExporter.generate(snapshot);
        final file = await createRosterShareFile(
            'aylik_analiz_${snapshot.start}_${snapshot.end}.xlsx', bytes);
        await SharePlus.instance.share(ShareParams(
            files: [file],
            text: 'Aylık görev analizi',
            sharePositionOrigin: origin));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Excel dışa aktarılamadı. Tekrar deneyin.')));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Aylık Görev Özeti',
            style: Theme.of(context).textTheme.titleLarge),
        MonthlyPeriodSelector(
            filter: widget.data.filter, onChanged: widget.onFilterChanged),
        Text(
            'Seçili dönem: ${report.start} — ${report.end} (${monthlyCount(report.totalDays)} gün)'),
        Text(
            '${report.teamLabel} · ${report.dutyLabel} · Durum: $_statusLabel'),
        const SizedBox(height: 12),
        FilledButton.icon(
            key: const ValueKey('monthly-export'),
            onPressed: exporting ? null : _export,
            icon: exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            label:
                Text(exporting ? 'Excel hazırlanıyor…' : 'Excel dışa aktar')),
        const SizedBox(height: 12),
        MonthlyPersonnelSummary(report: report),
        if (report.assignmentCount == 0)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Seçilen dönemde görev kaydı bulunamadı.')),
        MonthlyDailyChart(report: report),
        MonthlyReportSections(report: report),
        const SizedBox(height: 12),
        Card(
            child: ExpansionTile(
                title: const Text('Veri kapsamı ve kalite'),
                subtitle: Text(
                    '${monthlyCount(report.unknownTeamAssignments)} timi bilinmeyen · ${monthlyCount(report.unclassifiedAssignments)} sınıflandırılmamış'),
                childrenPadding: const EdgeInsets.all(12),
                children: [
              Text('Referans: ${DateFormat('dd.MM.yyyy').format(report.asOf)}. '
                  'Gelecek tarihler planlanandır; geçmiş kayıtlar tamamlanmayı kanıtlamaz. '
                  'Kayıt yok, görev yapılmadığı anlamına gelmez.'),
              Text(
                  'Tim bilgisi bilinen: ${monthlyCount(report.knownTeamAssignments)}; '
                  'bilinmeyen: ${monthlyCount(report.unknownTeamAssignments)}; '
                  'sınıflandırılmamış: ${monthlyCount(report.unclassifiedAssignments)}. '
                  'Tim kapsamı, tim bilgisi bilinen görevlendirmelerin payıdır.'),
              const Text(
                  'Sayılar faaliyet başlangıç tarihindeki kişi-görev kayıtlarıdır. '
                  'İki güne yayılan görev ikinci kez sayılmaz. Görev alanına karışmış '
                  'personel satırları yalnız doğrulanabiliyorsa faaliyet başlığındaki '
                  'görevle gösterilir. Kaynak kayıtlar değiştirilmez; belirsiz etiketler korunur.'),
              if (widget.data.duplicateAssignments > 0 ||
                  widget.data.possibleDuplicateActivities > 0)
                Text(
                    'Kaynakta yinelenen atama: ${monthlyCount(widget.data.duplicateAssignments)}; '
                    'olası yinelenen faaliyet: ${monthlyCount(widget.data.possibleDuplicateActivities)}.'),
            ])),
      ]);

  String get _statusLabel => switch (report.status) {
        'onaylandi' => 'Onaylanan',
        'beklemede' => 'Bekleyen',
        'reddedildi' => 'Reddedilen',
        _ => report.status,
      };
}
