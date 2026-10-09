import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
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
        if (cards.isEmpty) Text(context.l10n.excelPickerNoExtraCards),
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
        title: Text(context.l10n.excelPickerSelectCardsTitle),
        content: SizedBox(
          width: 600,
          height: (MediaQuery.sizeOf(context).height * 0.5).clamp(160.0, 360.0),
          child: ListView(
            children: [
              Text(context.l10n.excelPickerNotice),
              ..._section(
                context.l10n.excelPickerSameDayCards,
                widget.currentActivities,
                'current',
              ),
              ..._section(
                  context.l10n.excelPickerPreviousDayCards, widget.activities, 'previous'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonDismiss),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {...selected}),
            child: Text(context.l10n.excelPickerPreviewButton(selected.length)),
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
        title: Text(dialogContext.l10n.excelPickerCombinedPreviewTitle),
        content: SizedBox(
          width: 600,
          height: (MediaQuery.sizeOf(dialogContext).height * 0.5).clamp(
            160.0,
            360.0,
          ),
          child: ListView(
            children: [
              Text(dialogContext.l10n.excelPickerCombinedNotice(rows.length)),
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
            child: Text(context.l10n.commonDismiss),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.excelPickerSelectExport),
          ),
        ],
      ),
    ) ??
    false;
