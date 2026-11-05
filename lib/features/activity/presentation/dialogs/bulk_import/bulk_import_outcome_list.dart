import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'bulk_import_confirm_section.dart';

class BulkImportOutcomeList extends StatelessWidget {
  const BulkImportOutcomeList(
      {required this.outcomes, this.description = '', super.key});
  final List<ActivityImportOutcome> outcomes;
  final String description;

  @override
  Widget build(BuildContext context) => Scrollbar(
      child: ListView.separated(
          key: const Key('bulk-import-outcome-list'),
          padding: EdgeInsets.zero,
          itemCount: outcomes.length + (description.isEmpty ? 0 : 1),
          separatorBuilder: (_, __) => Divider(color: context.cardBorderColor),
          itemBuilder: (context, index) {
            if (description.isNotEmpty && index == 0) {
              return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(description,
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 12)));
            }
            final item = outcomes[index - (description.isEmpty ? 0 : 1)];
            final added = item.status == ActivityImportStatus.added;
            final color = added ? context.accentOrOlive : context.pendingColor;
            final reason = switch (item.status) {
              ActivityImportStatus.added => 'Personele görev eklendi',
              ActivityImportStatus.alreadyAssigned => 'Bu kartta zaten kayıtlı',
              ActivityImportStatus.conflict => 'Aynı gün görev kaydı var',
            };
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(top: 4, right: 12),
                          child: Icon(
                              added ? Icons.check_circle_outline : Icons.block,
                              color: color,
                              size: 25)),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('${item.rank} ${item.name}'.trim(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 3),
                            Text(
                                '${item.activityName} · ${BulkImportConfirmSection.displayDate(item.date)} · ${item.duty}',
                                style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 13)),
                            if (item.existingDescription?.trim().isNotEmpty ??
                                false)
                              Text('Mevcut kayıt: ${item.existingDescription}',
                                  style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 13)),
                            const SizedBox(height: 3),
                            Text(reason,
                                style: TextStyle(color: color, fontSize: 13)),
                          ])),
                    ]));
          }));
}
