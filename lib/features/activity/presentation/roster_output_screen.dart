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

Future<int?> _authorizedTeam(ProviderContainer container) async {
  final session = container.read(userSessionProvider);
  if (session == null) throw _SessionException();
  if (session.isAdmin) return null;
  final team = await container
      .read(personnelRepositoryProvider)
      .currentCommanderTeam(session.username);
  if (team == null) throw _TeamRevokedException();
  return team;
}

Future<List<MilitaryRosterRow>> _loadRosterRows(
  ProviderContainer container,
  String date,
  List<GunlukFaaliyetTableData> sources,
  int? selectedSquadId,
) async {
  final team = await _authorizedTeam(container);
  final db = container.read(databaseProvider);
  final people = await db.select(db.personelTable).get();
  final squads = await db.select(db.timTable).get();
  return CombinedHeybetExcelService(db).buildSelected(
    date: date,
    sources: sources,
    personnelById: {for (final person in people) person.id: person},
    squadNames: {for (final squad in squads) squad.id: squad.timAdi},
    authorizedTeamId: team,
    selectedSquadId: selectedSquadId,
  );
}

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
  bool _countsLoading = false;
  bool _showOrder = false;
  bool _showPreviousDay = false;
  Map<int, Set<int>> _cardPeople = {};
  int _loadGeneration = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final date = _date;
    final generation = ++_loadGeneration;
    try {
      final service = CombinedHeybetExcelService(ref.read(databaseProvider));
      final team = await _authorizedTeam(
        ProviderScope.containerOf(context, listen: false),
      );
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
      if (!mounted || date != _date || generation != _loadGeneration) return;
      setState(() {
        _current = lists[0];
        _previous = lists[1];
        _currentIds.removeWhere((id) => !_current.any((card) => card.id == id));
        _previousIds.removeWhere(
          (id) => !_previous.any((card) => card.id == id),
        );
        _loading = false;
        _countsLoading = true;
        _cardPeople = {};
      });
      _loadCardCounts(date, generation, [...lists[0], ...lists[1]]);
    } catch (error) {
      if (mounted && date == _date && generation == _loadGeneration) {
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

  Future<void> _loadCardCounts(
    String date,
    int generation,
    List<GunlukFaaliyetTableData> cards,
  ) async {
    try {
      final entries = <int, Set<int>>{};
      for (final card in cards) {
        final rows = await _loadRows(date, [card]);
        entries[card.id] =
            rows.map((row) => row.personelId).whereType<int>().toSet();
        if (!mounted || date != _date || generation != _loadGeneration) return;
        setState(() => _cardPeople = {...entries});
      }
      if (!mounted || date != _date || generation != _loadGeneration) return;
      setState(() {
        _cardPeople = entries;
        _countsLoading = false;
      });
    } catch (_) {
      if (!mounted || date != _date || generation != _loadGeneration) return;
      setState(() => _countsLoading = false);
    }
  }

  Set<int> _peopleFor(Iterable<int> ids) => {
        for (final id in ids) ...?_cardPeople[id],
      };

  bool get _selectedCountsReady =>
      [..._currentIds, ..._previousIds].every(_cardPeople.containsKey);

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
  ) =>
      _loadRosterRows(
        ProviderScope.containerOf(context, listen: false),
        date,
        sources,
        widget.selectedSquadId,
      );

  Future<void> _preview() async {
    if (_working || _currentIds.isEmpty && _previousIds.isEmpty) return;
    final sources = [
      ..._ordered(_current, _currentIds),
      ..._ordered(_previous, _previousIds),
    ];
    final date = _date;
    final container = ProviderScope.containerOf(context, listen: false);
    final selectedSquadId = widget.selectedSquadId;
    Future<List<MilitaryRosterRow>> loadRows() =>
        _loadRosterRows(container, date, sources, selectedSquadId);
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final List<MilitaryRosterRow> rows;
      try {
        rows = await loadRows();
      } finally {
        // Browser history can restore this screen before push's Future completes.
        if (mounted) setState(() => _working = false);
      }
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
          loadRows: loadRows,
        ),
      );
      if (mounted) _loadCards();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
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
      _showPreviousDay = false;
      _showOrder = false;
      _cardPeople = {};
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

  String _shortDate(DateTime day) => DateFormat('d MMM', 'tr').format(day);

  Widget _metric(String label, int count, bool ready) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFFBDD4D7))),
              const SizedBox(height: 3),
              Text(
                ready ? '$count kişi' : '—',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      );

  Widget _summary(bool ready) {
    final today = _peopleFor(_currentIds);
    final yesterday = _peopleFor(_previousIds);
    final unique = {...today, ...yesterday}.length;
    final common = today.intersection(yesterday).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173547), Color(0xFF0E4F4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF34716F)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ÇIKTI ÖZETİ',
              style: TextStyle(
                  fontSize: 11, letterSpacing: 1.2, color: Color(0xFF9CC6CC))),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(ready ? '$unique' : '—',
                  key: const Key('roster-total-people'),
                  style: const TextStyle(
                      fontSize: 48,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(width: 8),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Text('benzersiz kişi',
                      maxLines: 2,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            _metric('Bugün', today.length, ready),
            const SizedBox(width: 8),
            _metric('Önceki gün', yesterday.length, ready),
          ]),
          const SizedBox(height: 10),
          Text(
            ready
                ? _currentIds.isEmpty && _previousIds.isEmpty
                    ? 'Kart seçtikçe kişi sayısı güncellenir'
                    : common == 0
                        ? '✓ Ortak kişi yok'
                        : '✓ $common ortak kişi çıktıda bir kez yer alır'
                : _countsLoading
                    ? 'Kişi sayıları hesaplanıyor…'
                    : 'Kişi sayıları alınamadı',
            style: const TextStyle(fontSize: 11, color: Color(0xFFB3DAD5)),
          ),
        ],
      ),
    );
  }

  Widget _dayTab(String label, String date, int count, bool selected,
          VoidCallback onTap) =>
      Expanded(
        child: Material(
          color: selected ? const Color(0xFF244A52) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: Key(
                label == 'Bugün' ? 'roster-today-tab' : 'roster-previous-tab'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
              child: Column(children: [
                Text('$label · $date',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? const Color(0xFFC0FCF1) : null)),
                Text('$count kart seçili',
                    style: TextStyle(
                        fontSize: 10,
                        color: selected ? const Color(0xFF8CEBDC) : null)),
              ]),
            ),
          ),
        ),
      );

  Widget _cardTile(
      GunlukFaaliyetTableData card, List<int> ids, String prefix, bool ready) {
    final selected = ids.contains(card.id);
    final colors = Theme.of(context).colorScheme;
    final teal = const Color(0xFF58DECC);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.30)
            : colors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: selected
                  ? teal.withValues(alpha: 0.65)
                  : colors.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          key: ValueKey(selected
              ? 'selected-card-${card.id}'
              : '$prefix-activity-${card.id}'),
          onTap: _working
              ? null
              : () => setState(() {
                    if (selected) {
                      ids.remove(card.id);
                    } else {
                      ids.add(card.id);
                    }
                  }),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF146864)
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(selected ? Icons.check : Icons.add,
                    size: 22,
                    color: selected ? Colors.white : colors.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(card.faaliyetAdi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(selected ? 'Çıktıya eklendi' : 'Eklemek için dokun',
                        style: TextStyle(
                            fontSize: 11, color: colors.onSurfaceVariant)),
                  ])),
              const SizedBox(width: 8),
              Text(ready ? '${_cardPeople[card.id]!.length} kişi' : '—',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? teal : colors.onSurface)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(context.l10n.rosterOutputTitle),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                    children: [
                      Row(children: [
                        const Expanded(
                            child: Text('SEÇİLEN TARİH',
                                style: TextStyle(
                                    fontSize: 11, letterSpacing: 1.1))),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 176),
                          child: OutlinedButton.icon(
                            key: const Key('roster-date'),
                            onPressed: _working ? null : _pickDate,
                            icon: const Icon(Icons.calendar_today_outlined,
                                size: 16),
                            label: Text(
                              DateFormat(
                                MediaQuery.sizeOf(context).width < 360
                                    ? 'dd.MM.yyyy'
                                    : 'd MMMM yyyy',
                                'tr',
                              ).format(
                                  DateFormat('yyyy-MM-dd').parseStrict(_date)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _summary(_selectedCountsReady),
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
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: Text('Kartları seç',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700))),
                        TextButton(
                          key: const Key('roster-sort'),
                          onPressed: _currentIds.isEmpty && _previousIds.isEmpty
                              ? null
                              : () => setState(() => _showOrder = !_showOrder),
                          child: Text(_showOrder
                              ? 'Sıralamayı kapat'
                              : MediaQuery.sizeOf(context).width < 360
                                  ? 'Sırala ↗'
                                  : 'Seçilenleri sırala ↗'),
                        ),
                      ]),
                      if (_showOrder) ...[
                        Text(context.l10n.rosterReorderHint,
                            style: Theme.of(context).textTheme.bodySmall),
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
                      ],
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(children: [
                          _dayTab(
                              'Bugün',
                              _shortDate(DateTime.parse(_date)),
                              _currentIds.length,
                              !_showPreviousDay,
                              () => setState(() => _showPreviousDay = false)),
                          _dayTab(
                              'Önceki gün',
                              _shortDate(DateTime.parse(_date)
                                  .subtract(const Duration(days: 1))),
                              _previousIds.length,
                              _showPreviousDay,
                              () => setState(() => _showPreviousDay = true)),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: Text(
                                _showPreviousDay
                                    ? 'Önceki günün kartları'
                                    : 'Bugünün kartları',
                                style: Theme.of(context).textTheme.bodySmall)),
                        Text(
                            '${_showPreviousDay ? _previousIds.length : _currentIds.length} seçili',
                            style: Theme.of(context).textTheme.bodySmall),
                      ]),
                      const SizedBox(height: 8),
                      if ((_showPreviousDay ? _previous : _current).isEmpty)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(context.l10n.rosterNoCardsForDay)),
                      for (final card
                          in _showPreviousDay ? _previous : _current)
                        _cardTile(
                            card,
                            _showPreviousDay ? _previousIds : _currentIds,
                            _showPreviousDay ? 'previous' : 'current',
                            _cardPeople.containsKey(card.id)),
                      const SizedBox(height: 4),
                      Text(
                          'İki günün kartları ayrı kalır. Ortak kişiler çıktıda bir kez yer alır.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              key: const Key('roster-preview'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5CE1CE),
                foregroundColor: const Color(0xFF062A2D),
              ),
              onPressed: _loading ||
                      _working ||
                      _currentIds.isEmpty && _previousIds.isEmpty
                  ? null
                  : _preview,
              icon: const Icon(Icons.preview_outlined),
              label: Text(_working
                  ? context.l10n.rosterPreparing
                  : _selectedCountsReady
                      ? '${_peopleFor([
                              ..._currentIds,
                              ..._previousIds
                            ]).length} kişiyle önizle'
                      : context.l10n.rosterPreviewWithCount(
                          _currentIds.length + _previousIds.length)),
            ),
          ),
        ),
      );
}
