import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/roster_selected_cards.dart';
import 'package:personelapp2/features/activity/services/combined_heybet_excel_service.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

class _SessionException implements Exception {}
class _TeamRevokedException implements Exception {}

class RosterOutputScreen extends ConsumerStatefulWidget {
  const RosterOutputScreen({
    super.key,
    required this.initialDate,
    this.selectedSquadId,
  });
  final String initialDate;
  final int? selectedSquadId;
  @override
  ConsumerState<RosterOutputScreen> createState() => _RosterOutputScreenState();
}

class _RosterOutputScreenState extends ConsumerState<RosterOutputScreen> {
  late String _date = widget.initialDate;
  List<GunlukFaaliyetTableData> _current = [];
  List<GunlukFaaliyetTableData> _previous = [];
  final _currentIds = <int>[];
  final _previousIds = <int>[];
  bool _loading = true;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<int?> _authorizedTeam() async {
    final session = ref.read(userSessionProvider);
    if (session == null) throw _SessionException();
    if (session.isAdmin) return null;
    final team = await ref
        .read(personnelRepositoryProvider)
        .currentCommanderTeam(session.username);
    if (team == null) throw _TeamRevokedException();
    return team;
  }

  Future<void> _loadCards() async {
    final date = _date;
    try {
      final service = CombinedHeybetExcelService(ref.read(databaseProvider));
      final team = await _authorizedTeam();
      final day = DateFormat('yyyy-MM-dd').parseStrict(date);
      final previous = DateFormat('yyyy-MM-dd')
          .format(DateTime(day.year, day.month, day.day - 1));
      final lists = await Future.wait([
        service.listActivitiesForDate(
          date,
          authorizedTeamId: team,
          selectedSquadId: widget.selectedSquadId,
        ),
        service.listActivitiesForDate(
          previous,
          authorizedTeamId: team,
          selectedSquadId: widget.selectedSquadId,
        ),
      ]);
      if (!mounted || date != _date) return;
      setState(() {
        _current = lists[0];
        _previous = lists[1];
        _currentIds.removeWhere((id) => !_current.any((card) => card.id == id));
        _previousIds.removeWhere(
          (id) => !_previous.any((card) => card.id == id),
        );
        _loading = false;
      });
    } catch (error) {
      if (mounted && date == _date) {
        final message = switch (error) {
          _SessionException() => context.l10n.authSessionUnverified,
          _TeamRevokedException() =>
            context.l10n.rosterOutputCommanderTeamRevoked,
          _ => '$error',
        };
        setState(() {
          _error = message;
          _loading = false;
        });
      }
    }
  }

  List<GunlukFaaliyetTableData> _ordered(
    List<GunlukFaaliyetTableData> available,
    List<int> ids,
  ) {
    final byId = {for (final card in available) card.id: card};
    return [for (final id in ids) byId[id]!];
  }

  Future<List<MilitaryRosterRow>> _loadRows(
    String date,
    List<GunlukFaaliyetTableData> sources,
  ) async {
    final team = await _authorizedTeam();
    final db = ref.read(databaseProvider);
    final people = await db.select(db.personelTable).get();
    final squads = await db.select(db.timTable).get();
    return CombinedHeybetExcelService(db).buildSelected(
      date: date,
      sources: sources,
      personnelById: {for (final person in people) person.id: person},
      squadNames: {for (final squad in squads) squad.id: squad.timAdi},
      authorizedTeamId: team,
      selectedSquadId: widget.selectedSquadId,
    );
  }

  Future<void> _preview() async {
    if (_working || _currentIds.isEmpty && _previousIds.isEmpty) return;
    final sources = [
      ..._ordered(_current, _currentIds),
      ..._ordered(_previous, _previousIds),
    ];
    final date = _date;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final rows = await _loadRows(date, sources);
      if (!mounted) return;
      if (rows.isEmpty) {
        setState(
          () => _error = context.l10n.rosterNoApprovedPersonnel,
        );
        return;
      }
      await AppNavigator.toRosterOutputPreview(
        context,
        args: RosterOutputPreviewArgs(
          date: date,
          sources: sources,
          rows: rows,
          loadRows: () => _loadRows(date, sources),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _pickDate() async {
    final day = DateFormat('yyyy-MM-dd').parseStrict(_date);
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    final next = DateFormat('yyyy-MM-dd').format(picked);
    if (next == _date) return;
    setState(() {
      _date = next;
      _currentIds.clear();
      _previousIds.clear();
      _current = [];
      _previous = [];
      _error = null;
      _loading = true;
    });
    await _loadCards();
  }

  void _remove(int id) => setState(() {
    _currentIds.remove(id);
    _previousIds.remove(id);
  });
  void _reorder(List<int> ids, int oldIndex, int newIndex) => setState(() {
    ids.insert(newIndex, ids.removeAt(oldIndex));
  });

  List<Widget> _available(
    String title,
    List<GunlukFaaliyetTableData> cards,
    List<int> ids,
    String prefix,
  ) {
    final unselected = cards.where((c) => !ids.contains(c.id)).toList();
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      if (cards.isEmpty)
        Text(context.l10n.rosterNoCardsForDay)
      else if (unselected.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.rosterAllCardsAdded,
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      for (final card in unselected)
        Card(
          child: ListTile(
            key: ValueKey('$prefix-activity-${card.id}'),
            title: Text(card.faaliyetAdi),
            subtitle: Text(card.tarih),
            trailing: const Icon(Icons.add_circle_outline),
            onTap: _working
                ? null
                : () => setState(() {
                    if (!ids.contains(card.id)) ids.add(card.id);
                  }),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: Text(context.l10n.rosterOutputTitle),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  OutlinedButton.icon(
                    key: const Key('roster-date'),
                    onPressed: _working ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      DateFormat('dd.MM.yyyy')
                          .format(DateFormat('yyyy-MM-dd').parseStrict(_date)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      context.l10n.rosterSelectCardsHint,
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (_error != null)
                    TextButton(
                      onPressed: _working
                          ? null
                          : () {
                              setState(() {
                                _loading = true;
                                _error = null;
                              });
                              _loadCards();
                            },
                      child: Text(context.l10n.rosterReload),
                    ),
                  Text(
                    context.l10n.rosterIncludedItemsCount(_currentIds.length + _previousIds.length),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    context.l10n.rosterReorderHint,
                  ),
                  RosterSelectedCards(
                    title: context.l10n.rosterSameDayOutputOrder,
                    cards: _ordered(_current, _currentIds),
                    startNumber: 1,
                    onRemove: _remove,
                    onReorder: (a, b) => _reorder(_currentIds, a, b),
                    enabled: !_working,
                  ),
                  RosterSelectedCards(
                    title: context.l10n.rosterPreviousDayOutputOrder,
                    cards: _ordered(_previous, _previousIds),
                    startNumber: _currentIds.length + 1,
                    onRemove: _remove,
                    onReorder: (a, b) => _reorder(_previousIds, a, b),
                    enabled: !_working,
                  ),
                  const Divider(),
                  ..._available(
                    context.l10n.rosterSameDayCards,
                    _current,
                    _currentIds,
                    'current',
                  ),
                  ..._available(
                    context.l10n.rosterPreviousDayCards,
                    _previous,
                    _previousIds,
                    'previous',
                  ),
                ],
              ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          key: const Key('roster-preview'),
          onPressed:
              _loading ||
                  _working ||
                  _currentIds.isEmpty && _previousIds.isEmpty
              ? null
              : _preview,
          icon: const Icon(Icons.preview_outlined),
          label: Text(
            _working
                ? context.l10n.rosterPreparing
                : context.l10n.rosterPreviewWithCount(_currentIds.length + _previousIds.length),
          ),
        ),
      ),
    ),
  );
}
