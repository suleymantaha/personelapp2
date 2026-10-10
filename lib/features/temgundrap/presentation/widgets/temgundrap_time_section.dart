import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_formatters.dart';

class TemgundrapTimeSection extends StatelessWidget {
  const TemgundrapTimeSection(
      {required this.startAt,
      required this.endAt,
      required this.onStartTap,
      required this.onEndTap,
      super.key});
  final DateTime startAt;
  final DateTime endAt;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            ListTile(
              key: const Key('operation-start-time'),
              leading: const Icon(Icons.play_circle_outline),
              title: Text(context.l10n.temgundrapStartTime),
              subtitle: Text(TemgundrapFormatters.militaryDateTime(startAt)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: onStartTap,
            ),
            ListTile(
              key: const Key('operation-end-time'),
              leading: const Icon(Icons.stop_circle_outlined),
              title: Text(context.l10n.temgundrapEndTime),
              subtitle: Text(TemgundrapFormatters.militaryDateTime(endAt)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: onEndTap,
            ),
          ])));
}
