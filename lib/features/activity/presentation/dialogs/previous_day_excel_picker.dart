import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

class PreviousDayExcelPicker extends StatefulWidget {
  const PreviousDayExcelPicker({required this.activities, super.key});
  final List<GunlukFaaliyetTableData> activities;

  @override
  State<PreviousDayExcelPicker> createState() => _PreviousDayExcelPickerState();
}

class _PreviousDayExcelPickerState extends State<PreviousDayExcelPicker> {
  final selected = <int>{};

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Önceki Günün Tüm Faaliyetleri'),
        content: SizedBox(
          width: 600,
          height: 360,
          child: widget.activities.isEmpty
              ? const Center(
                  child: Text('Önceki güne ait faaliyet bulunamadı.'))
              : ListView(children: [
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Excel’in altına eklenecek kartları seçin. Otomatik seçim yapılmaz.')),
                  for (final activity in widget.activities)
                    Card(
                        child: CheckboxListTile(
                      key: ValueKey('previous-activity-${activity.id}'),
                      value: selected.contains(activity.id),
                      title: Text(activity.faaliyetAdi),
                      subtitle: Text(
                          '${activity.tarih} • ${activity.olusturanKullanici}'),
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          selected.add(activity.id);
                        } else {
                          selected.remove(activity.id);
                        }
                      }),
                    )),
                ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, {...selected}),
              child: Text('Önizleme (${selected.length})')),
        ],
      );
}

Future<bool> confirmCombinedExcelPreview(
        BuildContext context, List<MilitaryRosterRow> rows) async =>
    await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Ayrı Excel Önizlemesi'),
              content: SizedBox(
                  width: 600,
                  height: 360,
                  child: ListView(children: [
                    Text(
                        '${rows.length} personel satırı • Yalnızca ayrı Excel’e aktarılır'),
                    for (final row in rows)
                      ListTile(
                          title: Text('${row.sNu}. ${row.adSoyad}'),
                          subtitle: Text(row.rutbe)),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Vazgeç')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Excel’i Paylaş')),
              ],
            )) ??
    false;
