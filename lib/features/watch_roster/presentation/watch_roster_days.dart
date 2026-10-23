import 'package:flutter/material.dart';
import '../domain/watch_roster.dart';
import 'watch_roster_details.dart';

class WatchRosterDays extends StatefulWidget {
  const WatchRosterDays({super.key, required this.month, required this.roster});
  final DateTime month;
  final WatchRoster roster;

  @override
  State<WatchRosterDays> createState() => _WatchRosterDaysState();
}

class _WatchRosterDaysState extends State<WatchRosterDays> {
  String? _selected;

  @override
  void didUpdateWidget(covariant WatchRosterDays oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month.year != widget.month.year ||
        oldWidget.month.month != widget.month.month) {
      _selected = null;
    }
  }

  void _open(String date) {
    setState(() => _selected = date);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) =>
          WatchRosterDetails(date: date, roster: widget.roster),
    );
  }

  @override
  Widget build(BuildContext context) {
    final month = widget.month;
    final first = DateTime(month.year, month.month);
    final offset = first.weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final rows = (offset + days + 6) ~/ 7;
    final dates = widget.roster.dates.toSet();
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      key: ValueKey('watch-days-${month.year}-${month.month}'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Column(children: [
              Row(children: [
                for (final label in [
                  'Pzt',
                  'Sal',
                  'Çar',
                  'Per',
                  'Cum',
                  'Cmt',
                  'Paz'
                ])
                  Expanded(
                      child: Center(
                          child: Text(label,
                              style: Theme.of(context).textTheme.labelMedium))),
              ]),
              const SizedBox(height: 8),
              for (var row = 0; row < rows; row++)
                Row(children: [
                  for (var column = 0; column < 7; column++)
                    Expanded(
                        child:
                            _cell(row * 7 + column - offset + 1, days, dates)),
                ]),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.circle, size: 7, color: colors.primary),
          const SizedBox(width: 8),
          const Flexible(child: Text('Onaylı nöbet kaydı bulunan gün')),
        ]),
        if (widget.roster.isEmpty)
          const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Bu ay için görüntülenebilir onaylı nöbet kaydı yok.',
                  textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _cell(int day, int days, Set<String> dates) {
    if (day < 1 || day > days) return const SizedBox(height: 52);
    final date = DateTime(widget.month.year, widget.month.month, day)
        .toIso8601String()
        .substring(0, 10);
    final selected = _selected == date;
    final marked = dates.contains(date);
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimary : colors.onSurface;
    return Semantics(
      key: ValueKey('watch-day-$date'),
      button: true,
      onTap: () => _open(date),
      selected: selected,
      label:
          '${date.split('-').reversed.join('.')} ${marked ? 'Nöbet kaydı var' : 'Kayıt yok'}',
      child: ExcludeSemantics(
          child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: selected
              ? colors.primary
              : marked
                  ? colors.primaryContainer
                  : colors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _open(date),
            child: SizedBox(
                height: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day',
                        style: TextStyle(
                            color: foreground, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: marked
                                ? (selected ? colors.onPrimary : colors.primary)
                                : Colors.transparent)),
                  ],
                )),
          ),
        ),
      )),
    );
  }
}
