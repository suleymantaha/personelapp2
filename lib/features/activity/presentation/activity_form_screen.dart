import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

enum _ExistingActivityAction { merge, createNew }

enum _PersonnelFilter { all, selected, units }

class _ExistingActivityChoice {
  const _ExistingActivityChoice({
    required this.action,
    this.activityId,
    this.updateDifferentAssignments = false,
  });

  final _ExistingActivityAction action;
  final int? activityId;
  final bool updateDifferentAssignments;
}

class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({super.key});

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  _PersonnelFilter _personnelFilter = _PersonnelFilter.all;
  bool _showNameError = false;

  static const _activityTemplates = [
    'Heybet',
    'Hazır Kıta',
    'Gülüşkür',
    'Nöbet',
    'Devriye',
    'Görev',
    'Diğer',
  ];

  // Maps personelId to selected DutyType
  final Map<int, String> _assignments = {};
  // Maps personelId to custom notes
  final Map<int, String> _notes = {};

  Future<_ExistingActivityChoice?> _chooseExistingActivity(
    List<ExistingActivityMatch> matches,
  ) {
    var selectedId = matches.first.activity.id;
    var updateDifferent = false;
    return showDialog<_ExistingActivityChoice>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selected = matches.firstWhere(
            (match) => match.activity.id == selectedId,
          );
          return AlertDialog(
            title: const Text('Aynı faaliyet zaten var'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selected.activity.tarih} tarihinde '
                    '“${selected.activity.faaliyetAdi}” adlı '
                    '${matches.length} kayıt bulundu.',
                  ),
                  const SizedBox(height: 12),
                  if (matches.length > 1)
                    DropdownButtonFormField<int>(
                      initialValue: selectedId,
                      decoration: const InputDecoration(
                        labelText: 'Güncellenecek faaliyet',
                        border: OutlineInputBorder(),
                      ),
                      items: matches
                          .map(
                            (match) => DropdownMenuItem(
                              value: match.activity.id,
                              child: Text(
                                '#${match.activity.id} • '
                                '${match.activity.faaliyetAdi}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedId = value;
                            updateDifferent = false;
                          });
                        }
                      },
                    ),
                  if (matches.length > 1) const SizedBox(height: 12),
                  Text('${selected.newPersonnelCount} yeni personel eklenecek'),
                  Text(
                    '${selected.unchangedPersonnelCount} personel zaten kayıtlı',
                  ),
                  Text(
                    '${selected.differentPersonnelCount} personelin '
                    'görev/not bilgisi farklı',
                  ),
                  if (selected.differentPersonnelCount > 0)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: updateDifferent,
                      title: const Text(
                        'Farklı görev/not bilgilerini güncelle',
                      ),
                      subtitle: const Text(
                        'Seçilmezse mevcut bilgiler korunur.',
                      ),
                      onChanged: (value) => setDialogState(
                        () => updateDifferent = value ?? false,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İPTAL'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  const _ExistingActivityChoice(
                    action: _ExistingActivityAction.createNew,
                  ),
                ),
                child: const Text('YENİ FAALİYET OLUŞTUR'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _ExistingActivityChoice(
                    action: _ExistingActivityAction.merge,
                    activityId: selectedId,
                    updateDifferentAssignments: updateDifferent,
                  ),
                ),
                child: const Text('MEVCUDA EKLE'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitActivity() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final name = _activityNameController.text.trim();
    final userSession = ref.read(userSessionProvider);

    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }

    final payload = _assignments.entries.where((e) => e.value.isNotEmpty).map((
      e,
    ) {
      final note = _notes[e.key]?.trim();
      return {
        'personelId': e.key,
        'gorevVeyaIzin': e.value,
        'aciklama': (note != null && note.isNotEmpty) ? note : null,
      };
    }).toList();

    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir personel için görev seçiniz.'),
        ),
      );
      return;
    }

    final repo = ref.read(activityRepositoryProvider);
    final isCommander = userSession?.isAdmin != true;
    final matches = await repo.findMatchingActivities(
      faaliyetAdi: name,
      tarih: dateStr,
      personnelAssignments: payload,
    );
    if (!mounted) return;

    ActivityMergeResult? mergeResult;
    if (matches.isNotEmpty) {
      final choice = await _chooseExistingActivity(matches);
      if (choice == null || !mounted) return;
      if (choice.action == _ExistingActivityAction.merge) {
        mergeResult = await repo.mergeAssignmentsIntoActivity(
          activityId: choice.activityId!,
          personnelAssignments: payload,
          updateDifferentAssignments: choice.updateDifferentAssignments,
          isCommander: isCommander,
        );
      } else {
        await repo.createActivityWithAssignments(
          faaliyetAdi: name,
          tarih: dateStr,
          olusturanKullanici: userSession?.username ?? 'admin',
          personnelAssignments: payload,
          isCommander: isCommander,
        );
      }
    } else {
      await repo.createActivityWithAssignments(
        faaliyetAdi: name,
        tarih: dateStr,
        olusturanKullanici: userSession?.username ?? 'admin',
        personnelAssignments: payload,
        isCommander: isCommander,
      );
    }

    if (mounted) {
      final msg = mergeResult != null
          ? '${mergeResult.addedCount} personel eklendi, '
              '${mergeResult.updatedCount} güncellendi, '
              '${mergeResult.skippedCount} kayıt korundu.'
          : isCommander
              ? 'Faaliyet Kaydedildi! Admin onayına gönderildi.'
              : 'Faaliyet Çizelgesi Kaydedildi & Çakışma Denetimi Yapıldı!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
              isCommander ? context.pendingColor : context.approvedColor,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _showBulkImportSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toplu metin içe aktar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Birden fazla faaliyet ve personel kaydını panodaki '
                'metinden hızlıca oluşturun.',
                style: context.textStyleSecondary,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  icon: const Icon(Icons.content_paste_go_rounded),
                  label: const Text('Metni yapıştır'),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final db = ref.read(databaseProvider);
                    final activityRepo = ref.read(activityRepositoryProvider);
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => BulkImportDialog(
                        database: db,
                        activityRepository: activityRepo,
                      ),
                    );
                    if (result == true && mounted) {
                      ref.invalidate(activityRepositoryProvider);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: context.accentSubtleBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: context.accentOrOlive, size: 22),
    );
  }

  Widget _buildPersonnelHeader(int selectedCount) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Görevlendirilecek Birlikler',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        if (selectedCount > 0)
          Container(
            key: const Key('selected-personnel-badge'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.accentSubtleBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$selectedCount seçili',
              style: TextStyle(
                color: context.accentOrOlive,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonnelControls() {
    return Column(
      children: [
        TextField(
          key: const Key('personnel-search-field'),
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Personel veya birlik ara',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Aramayı temizle',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: context.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.cardBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.cardBorderColor),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Tümü', _PersonnelFilter.all),
              const SizedBox(width: 8),
              _buildFilterChip('Seçili', _PersonnelFilter.selected),
              const SizedBox(width: 8),
              _buildFilterChip('Birlik', _PersonnelFilter.units),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, _PersonnelFilter filter) {
    return ChoiceChip(
      label: Text(label),
      selected: _personnelFilter == filter,
      showCheckmark: false,
      onSelected: (_) => setState(() => _personnelFilter = filter),
    );
  }

  Widget _buildBottomActionBar(int selectedCount) {
    return Material(
      elevation: 12,
      color: context.colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            return Row(
              children: [
                if (!isCompact)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$selectedCount personel',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          selectedCount == 0
                              ? 'Henüz görevlendirme yok'
                              : 'Görevlendirmeye hazır',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              context.textStyleSecondary.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                if (!isCompact) const SizedBox(width: 12),
                if (isCompact)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        key: const Key('save-activity-button'),
                        onPressed: _submitActivity,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Kaydet'),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      key: const Key('save-activity-button'),
                      onPressed: _submitActivity,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Görevlendirmeyi Kaydet'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;

    final personnelAsync = ref.watch(allPersonnelProvider);
    final squadsAsync = ref.watch(allSquadsProvider);
    final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final selectedPersonnelCount = _assignments.values
        .where((assignment) => assignment.isNotEmpty)
        .length;

    const adminOnlyDuties = [
      DutyOrLeaveType.heybetKomutani,
      DutyOrLeaveType.nobSb,
      DutyOrLeaveType.mebsNob,
      DutyOrLeaveType.garajNob,
      DutyOrLeaveType.ttzaNob,
      DutyOrLeaveType.kuleNob,
    ];

    const generalDuties = [
      DutyOrLeaveType.hazirKita,
      DutyOrLeaveType.guluskur,
      DutyOrLeaveType.heybet,
      DutyOrLeaveType.gorevli,
      DutyOrLeaveType.nobetci,
      DutyOrLeaveType.izinli,
      DutyOrLeaveType.istirahatli,
      DutyOrLeaveType.raporlu,
      DutyOrLeaveType.sevk,
      DutyOrLeaveType.diger,
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(
          'Faaliyet Çizelgesi',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Toplu metin yapıştır',
              icon: const Icon(Icons.content_paste_go_rounded),
              onPressed: _showBulkImportSheet,
            ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(selectedPersonnelCount),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ResponsiveCenter(
          maxWidth: 860,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorderColor),
                ),
                child: Column(
                  children: [
                    InkWell(
                      key: const Key('activity-date-row'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            _buildIconContainer(Icons.calendar_today_rounded),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Faaliyet tarihi',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Değiştirmek için dokunun',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              dateFormatted,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('activity-name-field'),
                      controller: _activityNameController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() => _showNameError = false),
                      decoration: InputDecoration(
                        labelText: 'Faaliyet adı',
                        hintText: 'Örn. Hazır Kıta',
                        prefixIcon: const Icon(Icons.assignment_outlined),
                        filled: true,
                        fillColor: context.accentSubtleBg,
                        errorText:
                            _showNameError ? 'Faaliyet adı zorunludur' : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _activityTemplates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final template = _activityTemplates[index];
                    final selected =
                        _activityNameController.text.trim() == template;
                    return ChoiceChip(
                      label: Text(template),
                      selected: selected,
                      showCheckmark: selected,
                      onSelected: (_) => setState(() {
                        _activityNameController.text =
                            template == 'Diğer' ? '' : template;
                        _showNameError = false;
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildPersonnelHeader(selectedPersonnelCount),
              const SizedBox(height: 12),
              _buildPersonnelControls(),
              const SizedBox(height: 10),

              personnelAsync.when(
                data: (rawPersonnelList) {
                  // If Commander, strictly filter by their squad
                  final personnelList = (!isAdmin && session?.timId != null)
                      ? rawPersonnelList
                          .where((p) => p.timId == session?.timId)
                          .toList()
                      : (!isAdmin && session?.timId == null)
                          ? <PersonelTableData>[]
                          : rawPersonnelList;

                  if (!isAdmin && session?.timId == null) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Henüz bir time atamadınız. Lütfen yöneticinizle (Admin) iletişime geçiniz.',
                        style: TextStyle(
                          color: context.rejectedColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  if (personnelList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Görevlendirilecek kayıtlı personel bulunamadı.',
                      ),
                    );
                  }

                  if (isAdmin) {
                    return squadsAsync.when(
                      data: (squads) {
                        final squadMap = {
                          for (final s in squads) s.id: s.timAdi,
                        };

                        final query = _searchController.text
                            .trim()
                            .toLowerCase();
                        final visiblePersonnel = personnelList.where((p) {
                          final matchesQuery = query.isEmpty ||
                              p.adSoyad.toLowerCase().contains(query) ||
                              p.birlik.toLowerCase().contains(query);
                          final matchesFilter = switch (_personnelFilter) {
                            _PersonnelFilter.all => true,
                            _PersonnelFilter.selected =>
                              _assignments.containsKey(p.id),
                            _PersonnelFilter.units => p.timId != null,
                          };
                          return matchesQuery && matchesFilter;
                        });
                        final grouped = <int?, List<PersonelTableData>>{};
                        for (final p in visiblePersonnel) {
                          grouped.putIfAbsent(p.timId, () => []).add(p);
                        }

                        final sortedTimIds = grouped.keys.toList()
                          ..sort((a, b) {
                            if (a == null) return 1;
                            if (b == null) return -1;
                            final nameA = squadMap[a] ?? '';
                            final nameB = squadMap[b] ?? '';
                            final wA =
                                MilitaryStructureHelper.getSquadOrderWeight(
                              nameA,
                            );
                            final wB =
                                MilitaryStructureHelper.getSquadOrderWeight(
                              nameB,
                            );
                            if (wA != wB) return wA.compareTo(wB);
                            return nameA.compareTo(nameB);
                          });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sortedTimIds.map((timId) {
                            final members = grouped[timId]!
                              ..sort(
                                (a, b) => getRankWeight(
                                  a.rutbe,
                                ).compareTo(getRankWeight(b.rutbe)),
                              );

                            final squadName = timId == null
                                ? 'Timsiz / Diğer Personeller'
                                : (squadMap[timId] ?? 'Bilinmeyen Tim');

                            final selectedCount = members
                                .where((p) => _assignments.containsKey(p.id))
                                .length;
                            final isSelected = selectedCount > 0;
                            return Card(
                              elevation: 0,
                              color: isSelected
                                  ? context.accentSubtleBg
                                  : context.colorScheme.surface,
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? context.accentOrOlive
                                      : context.cardBorderColor,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: ExpansionTile(
                                tilePadding:
                                    const EdgeInsets.fromLTRB(16, 4, 12, 4),
                                title: Text(
                                  squadName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.accentOrOlive,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: isSelected
                                          ? Icon(
                                              Icons.check_circle_rounded,
                                              color: context.accentOrOlive,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                    SizedBox(
                                      width: 44,
                                      child: PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_vert_rounded,
                                          size: 22,
                                        ),
                                        tooltip: 'Time Toplu Görev Ata',
                                        onSelected: (duty) {
                                        setState(() {
                                          for (final p in members) {
                                            if (duty == 'CLEAR') {
                                              _assignments.remove(p.id);
                                            } else {
                                              _assignments[p.id] = duty;
                                            }
                                          }
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              duty == 'CLEAR'
                                                  ? '$squadName görevleri temizlendi.'
                                                  : '$squadName personelinin tümüne "$duty" atandı.',
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                        },
                                        itemBuilder: (ctx) => [
                                        PopupMenuItem(
                                          enabled: false,
                                          child: Text(
                                            '⚡ TIME TOPLU GÖREV ATA',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: context.accentOrOlive,
                                            ),
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        ...generalDuties.map(
                                          (d) => PopupMenuItem<String>(
                                            value: d,
                                            child: Text('Tümüne "$d" Ata'),
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        PopupMenuItem<String>(
                                          value: 'CLEAR',
                                          child: Text(
                                            'Görevleri Sıfırla',
                                            style: TextStyle(
                                              color: context.rejectedColor,
                                            ),
                                          ),
                                        ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 100,
                                      height: 28,
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.accentOrOlive,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${members.length} personel',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: context.onAccentOrOlive,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Divider(
                                    height: 1,
                                    color: context.cardBorderColor,
                                  ),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: members.length,
                                    separatorBuilder: (context, index) =>
                                        Divider(
                                      height: 1,
                                      color: context.cardBorderColor,
                                    ),
                                    itemBuilder: (context, index) {
                                      final p = members[index];
                                      final currentSelection =
                                          _assignments[p.id];

                                      final availableDuties = [
                                        if (isAdmin) ...adminOnlyDuties,
                                        ...generalDuties,
                                        if (!isAdmin &&
                                            currentSelection != null &&
                                            adminOnlyDuties.contains(
                                              currentSelection,
                                            ))
                                          currentSelection,
                                      ];

                                      return Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${p.rutbe} ${p.adSoyad}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Birlik: ${p.birlik}',
                                                    style: TextStyle(
                                                      color:
                                                          context.textSecondary,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth:
                                                    context.responsiveValue(
                                                  mobile: 135,
                                                  tablet: 180,
                                                  desktop: 220,
                                                ),
                                              ),
                                              child: DropdownButton<String>(
                                                value: currentSelection,
                                                isDense: true,
                                                isExpanded: true,
                                                hint: Text(
                                                  'SEÇİNİZ',
                                                  style: TextStyle(
                                                    color:
                                                        context.accentOrOlive,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                items: availableDuties.map((d) {
                                                  final isAdminOnly =
                                                      adminOnlyDuties.contains(
                                                    d,
                                                  );
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: d,
                                                    child: Text(
                                                      d,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight: isAdminOnly
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: isAdminOnly
                                                            ? context
                                                                .accentOrOlive
                                                            : context
                                                                .textPrimary,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setState(() {
                                                      _assignments[p.id] = val;
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, st) => Text('Tim verileri alınamadı: $err'),
                    );
                  }

                  // If not admin (Team Commander), render a flat list (their own team sorted by rank weight)
                  personnelList.sort(
                    (a, b) => getRankWeight(
                      a.rutbe,
                    ).compareTo(getRankWeight(b.rutbe)),
                  );
                  final query = _searchController.text.trim().toLowerCase();
                  final visiblePersonnel = personnelList.where((p) {
                    final matchesQuery = query.isEmpty ||
                        p.adSoyad.toLowerCase().contains(query) ||
                        p.birlik.toLowerCase().contains(query);
                    final matchesFilter = switch (_personnelFilter) {
                      _PersonnelFilter.all => true,
                      _PersonnelFilter.selected =>
                        _assignments.containsKey(p.id),
                      _PersonnelFilter.units => p.timId != null,
                    };
                    return matchesQuery && matchesFilter;
                  }).toList();

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visiblePersonnel.length,
                    separatorBuilder: (context, _) =>
                        Divider(color: context.cardBorderColor),
                    itemBuilder: (context, index) {
                      final p = visiblePersonnel[index];
                      final currentSelection = _assignments[p.id];

                      final availableDuties = [
                        if (isAdmin) ...adminOnlyDuties,
                        ...generalDuties,
                        if (!isAdmin &&
                            currentSelection != null &&
                            adminOnlyDuties.contains(currentSelection))
                          currentSelection,
                      ];

                      return Card(
                        elevation: 0,
                        color: currentSelection != null
                            ? context.accentSubtleBg
                            : context.colorScheme.surface,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: currentSelection != null
                                ? context.accentOrOlive
                                : context.cardBorderColor,
                            width: currentSelection != null ? 1.5 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${p.rutbe} ${p.adSoyad}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          'Birlik: ${p.birlik}',
                                          style: TextStyle(
                                            color: context.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: context.responsiveValue(
                                        mobile: 135,
                                        tablet: 180,
                                        desktop: 220,
                                      ),
                                    ),
                                    child: DropdownButton<String>(
                                      value: currentSelection,
                                      isDense: true,
                                      isExpanded: true,
                                      hint: Text(
                                        'SEÇİNİZ',
                                        style: TextStyle(
                                          color: context.accentOrOlive,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      items: availableDuties.map((d) {
                                        final isAdminOnly =
                                            adminOnlyDuties.contains(d);
                                        return DropdownMenuItem<String>(
                                          value: d,
                                          child: Text(
                                            d,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: isAdminOnly
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isAdminOnly
                                                  ? context.accentOrOlive
                                                  : context.textPrimary,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _assignments[p.id] = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Text('Hata: $err'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
