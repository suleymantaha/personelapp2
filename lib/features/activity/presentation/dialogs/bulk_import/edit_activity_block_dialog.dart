import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

class EditActivityBlockDialog extends StatefulWidget {
  const EditActivityBlockDialog({
    required this.block,
    this.availableSquads = const [],
    super.key,
  });

  final ParsedActivityBlock block;
  final List<TimTableData> availableSquads;

  static Future<ParsedActivityBlock?> show(
    BuildContext context,
    ParsedActivityBlock block, {
    List<TimTableData> availableSquads = const [],
  }) {
    return showModalBottomSheet<ParsedActivityBlock>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => EditActivityBlockDialog(
        block: block,
        availableSquads: availableSquads,
      ),
    );
  }

  @override
  State<EditActivityBlockDialog> createState() =>
      _EditActivityBlockDialogState();
}

class _EditActivityBlockDialogState extends State<EditActivityBlockDialog> {
  late final TextEditingController _activityController;
  late final TextEditingController _teamController;
  late final TextEditingController _timeController;
  DateTime? _selectedDate;
  String? _selectedDuty;

  static const List<String> _quickDuties = [
    DutyOrLeaveType.heybet,
    DutyOrLeaveType.hazirKita,
    DutyOrLeaveType.guluskur,
    DutyOrLeaveType.gorevli,
    DutyOrLeaveType.heybetKomutani,
  ];

  static const List<String> _standardDuties = [
    DutyOrLeaveType.heybet,
    DutyOrLeaveType.hazirKita,
    DutyOrLeaveType.guluskur,
    DutyOrLeaveType.gorevli,
    DutyOrLeaveType.heybetKomutani,
    DutyOrLeaveType.nobSb,
    DutyOrLeaveType.mebsNob,
    DutyOrLeaveType.garajNob,
    DutyOrLeaveType.ttzaNob,
    DutyOrLeaveType.kuleNob,
    DutyOrLeaveType.nobetci,
    DutyOrLeaveType.diger,
  ];

  late final List<String> _dropdownOptions;

  static const String _defaultTeamOption = 'Varsayılan / Personel Timi';
  static const String _customTeamOption = 'DİĞER (Elle Yaz...)';

  late String _selectedTeamOption;
  late final List<String> _teamDropdownOptions;

  @override
  void initState() {
    super.initState();
    final initialActivity = widget.block.parsedActivityType.trim();
    final initialTeam = widget.block.parsedTimName.trim();
    _activityController = TextEditingController(text: initialActivity);
    _teamController = TextEditingController(text: initialTeam);
    _timeController = TextEditingController(text: widget.block.parsedTimeRange);
    _selectedDate = DateTime.tryParse(widget.block.parsedDate);

    final options = <String>[..._standardDuties];
    if (initialActivity.isNotEmpty &&
        !options.contains(initialActivity) &&
        initialActivity != DutyOrLeaveType.diger) {
      options.insert(0, initialActivity);
    }
    _dropdownOptions = options;

    if (options.contains(initialActivity)) {
      _selectedDuty = initialActivity;
    } else if (initialActivity.isEmpty) {
      _selectedDuty = null;
    } else {
      _selectedDuty = DutyOrLeaveType.diger;
    }

    final teamOpts = <String>[_defaultTeamOption];
    for (final squad in widget.availableSquads) {
      final name = squad.timAdi.trim();
      if (name.isNotEmpty && !teamOpts.contains(name)) {
        teamOpts.add(name);
      }
    }
    if (initialTeam.isNotEmpty && !teamOpts.contains(initialTeam)) {
      teamOpts.add(initialTeam);
    }
    teamOpts.add(_customTeamOption);
    _teamDropdownOptions = teamOpts;

    if (initialTeam.isEmpty) {
      _selectedTeamOption = _defaultTeamOption;
    } else if (teamOpts.contains(initialTeam)) {
      _selectedTeamOption = initialTeam;
    } else {
      _selectedTeamOption = _customTeamOption;
    }
  }

  @override
  void dispose() {
    _activityController.dispose();
    _teamController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _selectTeam(String option) {
    setState(() {
      _selectedTeamOption = option;
      if (option == _defaultTeamOption) {
        _teamController.text = '';
      } else if (option != _customTeamOption) {
        _teamController.text = option;
      }
    });
  }

  void _selectDuty(String duty) {
    setState(() {
      _selectedDuty = duty;
      if (duty == DutyOrLeaveType.diger) {
        // Keep existing text or clear for custom entry
      } else {
        _activityController.text = duty;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDate;
    final canSave =
        selectedDate != null && _activityController.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  color: context.accentOrOlive, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Faaliyet kartını düzenle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hızlı Seçim Çipleri (Quick Select Chips)
          Text(
            'Hızlı Görev Seçimi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickDuties.map((duty) {
                final isSelected = _activityController.text.trim() == duty;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      duty,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : context.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: context.accentOrOlive,
                    backgroundColor: Theme.of(context).cardColor,
                    onSelected: (selected) {
                      if (selected) _selectDuty(duty);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Görev / Faaliyet Türü Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedDuty != null &&
                    _dropdownOptions.contains(_selectedDuty)
                ? _selectedDuty
                : null,
            hint: const Text('Görev seç'),
            isExpanded: true,
            menuMaxHeight: modernDropdownMenuMaxHeight(context),
            borderRadius: modernDropdownBorderRadius,
            dropdownColor: modernDropdownColor(context),
            decoration: InputDecoration(
              labelText: 'Görev / Faaliyet Türü Seçin',
              prefixIcon: const Icon(Icons.list_alt_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: _dropdownOptions.map((d) {
              final label =
                  d == DutyOrLeaveType.diger ? 'DİĞER (Elle Yaz...)' : d;
              return DropdownMenuItem(
                value: d,
                child: Text(label),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) _selectDuty(val);
            },
          ),
          const SizedBox(height: 12),

          // Görev / Faaliyet Adı TextField
          TextField(
            key: const Key('bulk-edit-activity'),
            controller: _activityController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Görev / Faaliyet Adı (Elle Düzenle)',
              prefixIcon: const Icon(Icons.edit_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Takım / Tim Seçin Dropdown
          DropdownButtonFormField<String>(
            key: const Key('bulk-edit-team-dropdown'),
            initialValue: _teamDropdownOptions.contains(_selectedTeamOption)
                ? _selectedTeamOption
                : _customTeamOption,
            isExpanded: true,
            menuMaxHeight: modernDropdownMenuMaxHeight(context),
            borderRadius: modernDropdownBorderRadius,
            dropdownColor: modernDropdownColor(context),
            decoration: InputDecoration(
              labelText: 'Takım / Tim Seçin',
              prefixIcon: const Icon(Icons.groups_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: _teamDropdownOptions.map((t) {
              return DropdownMenuItem(
                value: t,
                child: Text(t),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) _selectTeam(val);
            },
          ),
          const SizedBox(height: 12),

          // Takım / Tim Adı TextField
          TextField(
            key: const Key('bulk-edit-team'),
            controller: _teamController,
            decoration: InputDecoration(
              labelText: 'Takım / Tim Adı (Elle Düzenle)',
              prefixIcon: const Icon(Icons.edit_note_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            key: const Key('bulk-edit-time'),
            controller: _timeController,
            decoration: InputDecoration(
              labelText: 'Saat aralığı (isteğe bağlı)',
              hintText: '08:00 - 19:30',
              prefixIcon: const Icon(Icons.schedule_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final initialDate = _selectedDate ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            icon: const Icon(Icons.calendar_today_rounded),
            label: Text(
              selectedDate == null
                  ? 'Tarih seç'
                  : '${selectedDate.day.toString().padLeft(2, '0')}.'
                      '${selectedDate.month.toString().padLeft(2, '0')}.'
                      '${selectedDate.year}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            key: const Key('bulk-edit-save'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: canSave
                ? () {
                    final activity = _activityController.text.trim();
                    final team = _teamController.text.trim();
                    final time = _timeController.text.trim();
                    final date = _selectedDate!;
                    Navigator.pop(
                      context,
                      ParsedActivityBlock(
                        rawTitle: widget.block.rawTitle,
                        parsedTimName: team,
                        parsedActivityType: activity,
                        parsedDate:
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                        parsedTimeRange: time.isEmpty ? null : time,
                        personnelList: widget.block.personnelList,
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('DEĞİŞİKLİKLERİ UYGULA'),
          ),
        ],
      ),
    );
  }
}
