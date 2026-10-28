import 'dart:math';

import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/services/roster_matrix_x_rule.dart';

class RosterPreviewPeopleSheet extends StatelessWidget {
  const RosterPreviewPeopleSheet({
    super.key,
    required this.result,
    required this.excluded,
  });

  final RosterMatrixXResult result;
  final bool excluded;

  @override
  Widget build(BuildContext context) {
    final count = excluded ? result.excludedCount : result.rows.length;
    final title = excluded
        ? context.l10n.rosterRuleExcludedTitle(count)
        : context.l10n.rosterRuleIncludedTitle(count);
    final height = min(
      MediaQuery.sizeOf(context).height * 0.68,
      120.0 + count * 72.0,
    );
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    key: const Key('roster-rule-sheet-close'),
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                key: const Key('roster-rule-people-sheet'),
                itemCount: count,
                itemBuilder: (context, index) {
                  final row = excluded
                      ? result.excludedPeople[index].row
                      : result.rows[index];
                  return ListTile(
                    key: Key('roster-rule-sheet-person-${row.personelId}'),
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(row.adSoyad),
                    subtitle: Text(row.rutbe),
                    trailing: excluded
                        ? Text(context.l10n.rosterRuleExcludedDayCount(
                            result.excludedPeople[index].xDays,
                          ))
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
