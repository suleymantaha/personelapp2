import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/temgundrap/domain/services/temgundrap_activity_converter.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';

class TemgundrapImportActivitiesDialog extends ConsumerStatefulWidget {
  const TemgundrapImportActivitiesDialog({
    super.key,
    required this.initialDate,
    this.existingOperations = const [],
  });

  final DateTime initialDate;
  final List<TemgundrapOperation> existingOperations;

  @override
  ConsumerState<TemgundrapImportActivitiesDialog> createState() =>
      _TemgundrapImportActivitiesDialogState();
}

class _TemgundrapImportActivitiesDialogState
    extends ConsumerState<TemgundrapImportActivitiesDialog> {
  late DateTime _selectedDate;
  bool _loading = true;
  List<GunlukFaaliyetTableData> _activities = [];
  List<FaaliyetPersonelAtamaTableData> _assignments = [];
  Map<int, PersonelTableData> _personnelMap = {};
  final Set<int> _selectedActivityIds = {};

  bool _isActivityAlreadyAdded(GunlukFaaliyetTableData act) =>
      TemgundrapActivityConverter.isAlreadyImported(
          act, widget.existingOperations);

  List<GunlukFaaliyetTableData> get _availableActivities =>
      _activities.where((act) => !_isActivityAlreadyAdded(act)).toList();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      final activities = await (db.select(db.gunlukFaaliyetTable)
            ..where((tbl) => tbl.tarih.equals(dateStr)))
          .get();

      final actIds = activities.map((a) => a.id).toSet();
      List<FaaliyetPersonelAtamaTableData> assignments = [];
      if (actIds.isNotEmpty) {
        assignments = await (db.select(db.faaliyetPersonelAtamaTable)
              ..where((tbl) => tbl.faaliyetId.isIn(actIds)))
            .get();
      }

      final personnelIds = assignments.map((a) => a.personelId).toSet();
      final personnel = personnelIds.isEmpty
          ? <PersonelTableData>[]
          : await (db.select(db.personelTable)
                ..where((tbl) => tbl.id.isIn(personnelIds)))
              .get();
      final pMap = {for (final p in personnel) p.id: p};

      if (!mounted) return;
      setState(() {
        _activities = activities;
        _assignments = assignments;
        _personnelMap = pMap;
        _selectedActivityIds.clear();
        // Default: only select activities that have NOT been imported yet
        for (final act in activities) {
          if (!_isActivityAlreadyAdded(act)) {
            _selectedActivityIds.add(act.id);
          }
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      await _loadActivities();
    }
  }

  void _toggleAll() {
    setState(() {
      if (_selectedActivityIds.length == _availableActivities.length) {
        _selectedActivityIds.clear();
      } else {
        _selectedActivityIds.addAll(_availableActivities.map((a) => a.id));
      }
    });
  }

  void _submit() {
    final selectedActivities = _availableActivities
        .where((a) => _selectedActivityIds.contains(a.id))
        .toList();
    if (selectedActivities.isEmpty) return;

    final selectedAssignments = _assignments
        .where((a) => _selectedActivityIds.contains(a.faaliyetId))
        .toList();

    final operations = TemgundrapActivityConverter.convertAll(
      activities: selectedActivities,
      allAssignments: selectedAssignments,
      personnelMap: _personnelMap,
    );

    Navigator.pop(context, operations);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateDisplay = DateFormat('dd.MM.yyyy').format(_selectedDate);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.playlist_add_check_rounded),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.temgundrapImportDialogTitle)),
          ]),
          TextButton.icon(
            icon: const Icon(Icons.calendar_month, size: 18),
            label: Text(dateDisplay),
            onPressed: _pickDate,
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _activities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.temgundrapImportDialogNoActivities,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.temgundrapImportDialogSubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          TextButton(
                            onPressed: _toggleAll,
                            child: Text(
                              _selectedActivityIds.length ==
                                      _availableActivities.length
                                  ? 'Seçimi Kaldır'
                                  : 'Tümünü Seç',
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _activities.length,
                          itemBuilder: (context, index) {
                            final act = _activities[index];
                            final isSelected =
                                _selectedActivityIds.contains(act.id);
                            final personCount = _assignments
                                .where((a) => a.faaliyetId == act.id)
                                .length;
                            final isAdded = _isActivityAlreadyAdded(act);

                            return CheckboxListTile(
                              key: Key('activity-import-${act.id}'),
                              value: isSelected,
                              title: Text(
                                act.faaliyetAdi,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isAdded && !isSelected
                                      ? Colors.grey
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                '$personCount Personel Görevli${isAdded ? ' • (Zaten Eklendi)' : ''}',
                                style: TextStyle(
                                  color: isAdded ? Colors.teal : null,
                                ),
                              ),
                              onChanged: isAdded
                                  ? null
                                  : (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedActivityIds.add(act.id);
                                        } else {
                                          _selectedActivityIds.remove(act.id);
                                        }
                                      });
                                    },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('submit-import-activities'),
          onPressed: _selectedActivityIds.isEmpty ? null : _submit,
          child: Text(
            l10n.temgundrapImportDialogSubmit(_selectedActivityIds.length),
          ),
        ),
      ],
    );
  }
}
