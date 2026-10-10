import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';

class PersonnelFormDialog extends ConsumerStatefulWidget {
  const PersonnelFormDialog({super.key, this.personnelToEdit});

  final PersonelTableData? personnelToEdit;

  @override
  ConsumerState<PersonnelFormDialog> createState() =>
      _PersonnelFormDialogState();
}

class _PersonnelFormDialogState extends ConsumerState<PersonnelFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _customRankController;
  late final TextEditingController _phoneController;

  String? _selectedRank;
  int? _selectedSquadId;

  bool _saving = false;

  bool get _isEditing => widget.personnelToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.personnelToEdit;
    _nameController = TextEditingController(text: p?.adSoyad ?? '');
    _unitController = TextEditingController(text: p?.birlik ?? '');
    _phoneController = TextEditingController(text: p?.telefon ?? '');

    if (p != null) {
      final normalizedRutbe = normalizeRank(p.rutbe);
      final isStandardRank = kAskeriRutbeler.contains(normalizedRutbe);
      _selectedRank = isStandardRank ? normalizedRutbe : 'DİĞER / ÖZEL RÜTBE';
      _customRankController = TextEditingController(
        text: isStandardRank ? '' : p.rutbe,
      );
      _selectedSquadId = p.timId;
    } else {
      _selectedRank = null;
      _customRankController = TextEditingController();
      _selectedSquadId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _customRankController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppNotifications.warning(context.l10n.personnelWarningEnterName);
      return;
    }

    if (_selectedRank == null) {
      AppNotifications.warning(context.l10n.personnelWarningSelectRank);
      return;
    }

    final finalRank = (_selectedRank == 'DİĞER / ÖZEL RÜTBE')
        ? _customRankController.text.trim()
        : _selectedRank!;

    var birlik = _unitController.text.trim();
    if (birlik.isEmpty && _selectedSquadId != null) {
      final squads = ref.read(allSquadsProvider).valueOrNull ?? [];
      final match = squads.where((s) => s.id == _selectedSquadId).firstOrNull;
      if (match != null) {
        birlik = MilitaryStructureHelper.getBolukName(match.timAdi);
      }
    }
    if (birlik.isEmpty) {
      birlik = 'Asayiş Timi';
    }

    final repo = ref.read(personnelRepositoryProvider);

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        final p = widget.personnelToEdit!;
        await repo.updatePersonnel(
          p.copyWith(
            adSoyad: name,
            rutbe: finalRank.isEmpty ? 'J.Er' : finalRank,
            birlik: birlik,
            telefon: Value(
              _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
            ),
            timId: Value(_selectedSquadId),
          ),
        );
      } else {
        await repo.addPersonnel(
          adSoyad: name,
          rutbe: finalRank.isEmpty ? 'J.Er' : finalRank,
          birlik: birlik,
          timId: _selectedSquadId,
          kayitTarihi: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          telefon: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        AppNotifications.error(
          context.l10n.personnelErrorSaveFailed('$error'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final squadsAsync = ref.watch(allSquadsProvider);
    final p = widget.personnelToEdit;

    return PopScope(
      canPop: !_saving,
      child: AbsorbPointer(
        absorbing: _saving,
        child: AlertDialog(
          title: Text(
            _isEditing
                ? context.l10n.personnelEditNamed('${p?.rutbe} ${p?.adSoyad}')
                : context.l10n.personnelAddTitle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.l10n.personnelFullName,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('personnel-phone-field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: context.l10n.personnelPhone,
                    hintText: '533 158 35 97',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  menuMaxHeight: modernDropdownMenuMaxHeight(context),
                  borderRadius: modernDropdownBorderRadius,
                  dropdownColor: modernDropdownColor(context),
                  initialValue: _selectedRank,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.personnelSelectRankHint,
                  ),
                  items: [
                    ...kAskeriRutbeler.map(
                      (r) => DropdownMenuItem(value: r, child: Text(r)),
                    ),
                    DropdownMenuItem(
                      value: 'DİĞER / ÖZEL RÜTBE',
                      child: Text(context.l10n.personnelCustomRankDropdownOption),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedRank = val);
                  },
                ),
                if (_selectedRank == 'DİĞER / ÖZEL RÜTBE') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customRankController,
                    decoration: InputDecoration(
                      labelText: context.l10n.personnelCustomRankLabel,
                      hintText: context.l10n.personnelCustomRankHint,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                squadsAsync.when(
                  data: (squads) => DropdownButtonFormField<int?>(
                    menuMaxHeight: modernDropdownMenuMaxHeight(context),
                    borderRadius: modernDropdownBorderRadius,
                    dropdownColor: modernDropdownColor(context),
                    initialValue: _selectedSquadId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.personnelSquadLabel,
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        child: Text(context.l10n.personnelIndependentSquad),
                      ),
                      ...squads.map(
                        (sq) => DropdownMenuItem<int?>(
                          value: sq.id,
                          child: Text(
                            '${sq.timAdi} (${MilitaryStructureHelper.getBolukName(sq.timAdi)})',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedSquadId = val);
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (err, st) => Text(
                    context.l10n.personnelSquadsLoadError(err.toString()),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _unitController,
                        decoration: InputDecoration(
                          labelText: context.l10n.personnelUnitLabel,
                          hintText: "Örn: 1'inci Bl.",
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      tooltip: context.l10n.personnelSelectUnitTooltip,
                      elevation: 5,
                      shadowColor: context.shadowColor,
                      surfaceTintColor: context.colorScheme.surface,
                      shape: modernPopupShape(context),
                      constraints: const BoxConstraints(
                        minWidth: 250,
                        maxWidth: 300,
                      ),
                      onSelected: (val) {
                        _unitController.text = val;
                      },
                      itemBuilder: (ctx) => [
                        ModernMenuHeader<String>(
                          title: context.l10n.personnelSelectUnitTitle,
                          subtitle: context.l10n.personnelFrequentlyUsedUnits,
                          icon: Icons.domain_outlined,
                        ),
                        const PopupMenuDivider(),
                        ...const [
                          "1'inci Bl.",
                          "2'nci Bl.",
                          "3'üncü Bl.",
                          "1'inci Bl. K.H",
                          "2'nci Bl. K.H",
                          "3'üncü Bl. K.H",
                          'K.H',
                        ].map(
                          (unit) => ModernPopupMenuItem(
                            option: ModernActionOption(
                              value: unit,
                              title: unit,
                              icon: Icons.business_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: Text(context.l10n.commonCancel.toUpperCase()),
            ),
            ElevatedButton(
              onPressed: _saving ? null : _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentOrOlive,
                foregroundColor: context.onAccentOrOlive,
              ),
              child: Text(
                _saving
                    ? context.l10n.commonSaving
                    : _isEditing
                    ? context.l10n.settingsUpdate
                    : context.l10n.commonSave.toUpperCase(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
