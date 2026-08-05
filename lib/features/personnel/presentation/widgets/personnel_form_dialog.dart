import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';

class PersonnelFormDialog extends ConsumerStatefulWidget {
  const PersonnelFormDialog({
    super.key,
    this.personnelToEdit,
  });

  final PersonelTableData? personnelToEdit;

  @override
  ConsumerState<PersonnelFormDialog> createState() =>
      _PersonnelFormDialogState();
}

class _PersonnelFormDialogState extends ConsumerState<PersonnelFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _customRankController;

  String? _selectedRank;
  int? _selectedSquadId;

  bool get _isEditing => widget.personnelToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.personnelToEdit;
    _nameController = TextEditingController(text: p?.adSoyad ?? '');
    _unitController = TextEditingController(text: p?.birlik ?? '');

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
    super.dispose();
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ad soyad giriniz.')),
      );
      return;
    }

    if (_selectedRank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen rütbe seçiniz.')),
      );
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

    if (_isEditing) {
      final p = widget.personnelToEdit!;
      await repo.updatePersonnel(
        p.copyWith(
          adSoyad: name,
          rutbe: finalRank.isEmpty ? 'J.Er' : finalRank,
          birlik: birlik,
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
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final squadsAsync = ref.watch(allSquadsProvider);
    final p = widget.personnelToEdit;

    return AlertDialog(
      title: Text(
        _isEditing
            ? '${p?.rutbe} ${p?.adSoyad} - Düzenle'
            : 'Yeni Personel Ekle',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              menuMaxHeight: modernDropdownMenuMaxHeight(context),
              borderRadius: modernDropdownBorderRadius,
              dropdownColor: modernDropdownColor(context),
              initialValue: _selectedRank,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Rütbe Seçiniz'),
              items: [
                ...kAskeriRutbeler.map(
                  (r) => DropdownMenuItem(value: r, child: Text(r)),
                ),
                const DropdownMenuItem(
                  value: 'DİĞER / ÖZEL RÜTBE',
                  child: Text('DİĞER / ÖZEL RÜTBE (Elle Gir)'),
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
                decoration: const InputDecoration(
                  labelText: 'Özel Rütbe Metni',
                  hintText: 'Örn: J.Uz.Çvş. (Kıd.Kd.Çvş)',
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
                decoration: const InputDecoration(
                  labelText: 'Bağlı Olduğu Tim',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    child: Text('Bağımsız / Tim Dışı'),
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
              error: (err, st) => Text('Timler yüklenemedi: $err'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Birlik / Bölük',
                      hintText: "Örn: 1'inci Bl.",
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  tooltip: 'Birlik seç',
                  elevation: 5,
                  shadowColor: context.shadowColor,
                  surfaceTintColor: context.colorScheme.surface,
                  shape: modernPopupShape(context),
                  constraints:
                      const BoxConstraints(minWidth: 250, maxWidth: 300),
                  onSelected: (val) {
                    _unitController.text = val;
                  },
                  itemBuilder: (ctx) => [
                    const ModernMenuHeader<String>(
                      title: 'Birlik seç',
                      subtitle: 'Sık kullanılan birlikler',
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İPTAL'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.accentOrOlive,
            foregroundColor: context.onAccentOrOlive,
          ),
          child: Text(_isEditing ? 'GÜNCELLE' : 'KAYDET'),
        ),
      ],
    );
  }
}
