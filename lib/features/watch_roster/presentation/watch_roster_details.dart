import 'package:flutter/material.dart';
import '../domain/watch_roster.dart';

class WatchRosterDetails extends StatelessWidget {
  const WatchRosterDetails(
      {super.key, required this.date, required this.roster});
  final String date;
  final WatchRoster roster;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(children: [
              Expanded(
                  child: Semantics(
                      header: true,
                      child: Text(date.split('-').reversed.join('.'),
                          style: Theme.of(context).textTheme.titleLarge))),
              IconButton(
                  key: const ValueKey('watch-day-close'),
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
          ),
          Flexible(
              child: SingleChildScrollView(
            key: const ValueKey('watch-day-details-scroll'),
            padding: EdgeInsets.fromLTRB(
                12, 0, 12, 16 + MediaQuery.paddingOf(context).bottom),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final duty in watchDuties.entries)
                    _DutyCard(
                        label: duty.value,
                        records: roster.records(date, duty.key)),
                ]),
          )),
        ]),
      );
}

class _DutyCard extends StatelessWidget {
  const _DutyCard({required this.label, required this.records});
  final String label;
  final List<WatchRecord> records;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Semantics(
                header: true,
                child: Text(label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            if (records.isEmpty) const Text('Kayıt yok'),
            for (final record in records) ...[
              Text(record.activityName,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final person in record.personnel)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person_outline, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(person.personnelName),
                              Text(
                                  person.teamName.isEmpty
                                      ? 'Timi bilinmiyor'
                                      : person.teamName,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ])),
                      ]),
                ),
              if (record != records.last) const Divider(),
            ],
          ]),
        ),
      );
}
