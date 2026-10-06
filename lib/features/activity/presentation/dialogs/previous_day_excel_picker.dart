import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

class PreviousDayExcelPicker extends StatefulWidget {
  const PreviousDayExcelPicker({
    required this.activities,
    this.currentActivities = const [],
    super.key,
  });
  final List<GunlukFaaliyetTableData> activities;
  final List<GunlukFaaliyetTableData> currentActivities;

  @override
  State<PreviousDayExcelPicker> createState() => _PreviousDayExcelPickerState();
}

class _PreviousDayExcelPickerState extends State<PreviousDayExcelPicker> {
  final selected = <int>{};

  List<Widget> _section(
    String title,
    List<GunlukFaaliyetTableData> cards,
    String keyPrefix,
  ) =>
      [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        if (cards.isEmpty) const Text('Bu güne ait ek kart bulunamadı.'),
        for (final activity in cards)
          Card(
            child: CheckboxListTile(
              key: ValueKey('$keyPrefix-activity-${activity.id}'),
              value: selected.contains(activity.id),
              title: Text(activity.faaliyetAdi),
              subtitle:
                  Text('${activity.tarih} • ${activity.olusturanKullanici}'),
              onChanged: (value) => setState(() {
                if (value == true) {
                  selected.add(activity.id);
                } else {
                  selected.remove(activity.id);
                }
              }),
            ),
          ),
      ];

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Çıktıya Eklenecek Kartlar'),
        content: SizedBox(
          width: 600,
          height: (MediaQuery.sizeOf(context).height * 0.5).clamp(160.0, 360.0),
          child: ListView(
            children: [
              const Text(
                'Ana Heybet kartı dahil edilir. Ek kartları seçin; aynı kişi çıktıda yalnızca bir kez yer alır.',
              ),
              ..._section(
                'Aynı Günün Kartları',
                widget.currentActivities,
                'current',
              ),
              ..._section(
                  'Önceki Günün Kartları', widget.activities, 'previous'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {...selected}),
            child: Text('Önizleme (${selected.length})'),
          ),
        ],
      );
}

Future<bool> confirmCombinedExcelPreview(
  BuildContext context,
  List<MilitaryRosterRow> rows, {
  List<GunlukFaaliyetTableData> sources = const [],
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Birleşik Çıktı Önizlemesi'),
        content: SizedBox(
          width: 600,
          height: (MediaQuery.sizeOf(dialogContext).height * 0.5).clamp(
            160.0,
            360.0,
          ),
          child: ListView(
            children: [
              Text(
                '${rows.length} personel • Her kişi bir kez • Toplam baskıda gösterilmez',
              ),
              for (final source in sources)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${source.tarih} • ${source.faaliyetAdi}'),
                ),
              const Divider(),
              for (final row in rows)
                ListTile(
                  title: Text('${row.sNu}. ${row.adSoyad}'),
                  subtitle: Text(row.rutbe),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Çıktı Seç'),
          ),
        ],
      ),
    ) ??
    false;
