import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';
import 'package:personelapp2/features/activity/presentation/activity_assignment_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_form_controls.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_form_header.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_personnel_duty_row.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_squad_expansion_tile.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/existing_activity_dialog.dart';

part 'activity_form_actions.dart';

class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({super.key});

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  PersonnelFilter _personnelFilter = PersonnelFilter.all;
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

  final Map<int, String> _assignments = {};
  final Map<int, String> _notes = {};

  @override
  void dispose() {
    _activityNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateState(VoidCallback callback) => setState(callback);

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;

    final personnelAsync = ref.watch(allPersonnelProvider);
    final squadsAsync = ref.watch(allSquadsProvider);
    final selectedPersonnelCount =
        _assignments.values.where((assignment) => assignment.isNotEmpty).length;

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
          maxWidth: AppSpacing.readableContentWidth,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ActivityFormHeader(
                selectedDate: _selectedDate,
                onPickDate: _pickDate,
                activityNameController: _activityNameController,
                showNameError: _showNameError,
                onNameChanged: (_) => setState(() => _showNameError = false),
                templates: _activityTemplates,
                onTemplateSelected: (template) => setState(() {
                  _activityNameController.text =
                      template == 'Diğer' ? '' : template;
                  _showNameError = false;
                }),
              ),
              const SizedBox(height: 24),
              ActivityFormControls(
                selectedCount: selectedPersonnelCount,
                searchController: _searchController,
                onSearchChanged: (_) => setState(() {}),
                onSearchCleared: () {
                  _searchController.clear();
                  setState(() {});
                },
                currentFilter: _personnelFilter,
                onFilterChanged: (filter) =>
                    setState(() => _personnelFilter = filter),
              ),
              const SizedBox(height: 10),
              personnelAsync.when(
                data: (rawPersonnelList) {
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

                        final query =
                            _searchController.text.trim().toLowerCase();
                        final visiblePersonnel = personnelList.where((p) {
                          final matchesQuery = query.isEmpty ||
                              p.adSoyad.toLowerCase().contains(query) ||
                              p.birlik.toLowerCase().contains(query);
                          final matchesFilter = switch (_personnelFilter) {
                            PersonnelFilter.all => true,
                            PersonnelFilter.selected =>
                              _assignments.containsKey(p.id),
                            PersonnelFilter.units => p.timId != null,
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

                            return ActivitySquadExpansionTile(
                              squadName: squadName,
                              members: members,
                              assignments: _assignments,
                              isAdmin: isAdmin,
                              adminOnlyDuties: adminOnlyDuties,
                              generalDuties: generalDuties,
                              onBatchAssign: (duty) {
                                setState(() {
                                  for (final p in members) {
                                    if (duty == 'CLEAR') {
                                      _assignments.remove(p.id);
                                    } else {
                                      _assignments[p.id] = duty;
                                    }
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      duty == 'CLEAR'
                                          ? '$squadName görevleri temizlendi.'
                                          : '$squadName personelinin tümüne "$duty" atandı.',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              onDutyChanged: (personId, duty) {
                                setState(() => _assignments[personId] = duty);
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, st) => Text('Tim verileri alınamadı: $err'),
                    );
                  }

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
                      PersonnelFilter.all => true,
                      PersonnelFilter.selected =>
                        _assignments.containsKey(p.id),
                      PersonnelFilter.units => p.timId != null,
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
                        child: ActivityPersonnelDutyRow(
                          personnel: p,
                          currentSelection: currentSelection,
                          availableDuties: availableDuties,
                          adminOnlyDuties: adminOnlyDuties,
                          onDutyChanged: (val) {
                            if (val != null) {
                              setState(() => _assignments[p.id] = val);
                            }
                          },
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

  Widget _buildBottomActionBar(int selectedCount) {
    return Material(
      elevation: 12,
      color: context.colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The long desktop/tablet CTA needs more horizontal room than a
            // typical phone provides once SafeArea padding is applied.
            final isCompact = constraints.maxWidth < 440;

            if (isCompact) {
              return SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  key: const Key('save-activity-button'),
                  onPressed: _submitActivity,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    selectedCount == 0
                        ? 'Kaydet'
                        : 'Kaydet ($selectedCount personel)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }

            return Row(
              children: [
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
                        style: context.textStyleSecondary.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      key: const Key('save-activity-button'),
                      onPressed: _submitActivity,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text(
                        'Görevlendirmeyi Kaydet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
