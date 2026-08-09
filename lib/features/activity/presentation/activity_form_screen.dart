import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/activity_assignment_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_details_step.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_form_controls.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_personnel_selection_step.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/existing_activity_dialog.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';

part 'activity_form_actions.dart';

class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({super.key});

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  late final ActivityFormDraft _draft;
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  PersonnelFilter _personnelFilter = PersonnelFilter.all;
  bool _showNameError = false;
  bool _allowPop = false;

  static const _activityTemplates = [
    'Heybet',
    'Hazır Kıta',
    'Gülüşkür',
    'Nöbet',
    'Devriye',
    'Görev',
    'Diğer',
  ];

  static const _adminOnlyDuties = [
    DutyOrLeaveType.heybetKomutani,
    DutyOrLeaveType.nobSb,
    DutyOrLeaveType.mebsNob,
    DutyOrLeaveType.garajNob,
    DutyOrLeaveType.ttzaNob,
    DutyOrLeaveType.kuleNob,
  ];

  static const _generalDuties = [
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

  @override
  void initState() {
    super.initState();
    _draft = ActivityFormDraft(initialDate: DateTime.now());
  }

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
    final selectedPersonnel = personnelAsync.asData?.value
            .where(
              (person) => _draft.selectedPersonnelIds.contains(person.id),
            )
            .toList() ??
        const <PersonelTableData>[];

    return PopScope(
      canPop: _allowPop || !_draft.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_draft.step == ActivityFormStep.activityDetails) {
          setState(_draft.goToPersonnelSelection);
          return;
        }
        final navigator = Navigator.of(context);
        final discard = await _confirmDiscardChanges();
        if (!mounted || !discard) return;
        setState(() => _allowPop = true);
        navigator.pop();
      },
      child: Scaffold(
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
            if (isAdmin && _draft.step == ActivityFormStep.personnelSelection)
              IconButton(
                tooltip: 'Toplu metin yapıştır',
                icon: const Icon(Icons.content_paste_go_rounded),
                onPressed: _showBulkImportSheet,
              ),
            const SizedBox(width: 8),
          ],
        ),
        bottomNavigationBar: _buildBottomActionBar(
          isAdmin: isAdmin,
          selectedPersonnel: selectedPersonnel,
        ),
        body: TurkishFlagWatermarkBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 600 ? 24.0 : 0.0;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.readableContentWidth,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: constraints.maxHeight,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: personnelAsync.when(
                        data: (rawPersonnel) => squadsAsync.when(
                          data: (squads) => _buildLoadedBody(
                            session: session,
                            isAdmin: isAdmin,
                            rawPersonnel: rawPersonnel,
                            squads: squads,
                          ),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (error, _) => _ErrorState(
                            message: 'Tim verileri alınamadı: $error',
                          ),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => _ErrorState(
                          message: 'Personel yüklenemedi: $error',
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedBody({
    required UserSessionState? session,
    required bool isAdmin,
    required List<PersonelTableData> rawPersonnel,
    required List<TimTableData> squads,
  }) {
    if (!isAdmin && session?.timId == null) {
      return const _ErrorState(
        message:
            'Henüz bir time atanmadınız. Lütfen yöneticinizle iletişime geçin.',
      );
    }

    final personnel = isAdmin
        ? List<PersonelTableData>.of(rawPersonnel)
        : rawPersonnel
            .where((person) => person.timId == session?.timId)
            .toList();
    if (personnel.isEmpty) {
      return const _ErrorState(
        message: 'Görevlendirilecek kayıtlı personel bulunamadı.',
      );
    }

    if (_draft.step == ActivityFormStep.personnelSelection) {
      return ActivityPersonnelSelectionStep(
        personnel: personnel,
        squads: squads,
        isAdmin: isAdmin,
        selectedPersonnelIds: _draft.selectedPersonnelIds,
        searchController: _searchController,
        filter: _personnelFilter,
        onSearchChanged: (_) => setState(() {}),
        onSearchCleared: () {
          _searchController.clear();
          setState(() {});
        },
        onFilterChanged: (filter) => setState(() => _personnelFilter = filter),
        onTogglePersonnel: (id) => setState(() => _draft.togglePersonnel(id)),
        onToggleSquad: (ids) => setState(() => _draft.toggleSquad(ids)),
      );
    }

    final selectedPersonnel = personnel
        .where((person) => _draft.selectedPersonnelIds.contains(person.id))
        .toList()
      ..sort(
          (a, b) => getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe)));
    final availableDuties = [
      if (isAdmin) ..._adminOnlyDuties,
      ..._generalDuties,
    ];

    return ActivityDetailsStep(
      draft: _draft,
      selectedPersonnel: selectedPersonnel,
      squadNames: {for (final squad in squads) squad.id: squad.timAdi},
      activityNameController: _activityNameController,
      activityTemplates: _activityTemplates,
      availableDuties: availableDuties,
      showNameError: _showNameError,
      onPickDate: _pickDate,
      onActivityChanged: (value) => setState(() {
        _draft.setActivityName(value);
        _showNameError = false;
      }),
      onActivityTemplateSelected: (template) => setState(() {
        final value = template == 'Diğer' ? '' : template;
        _activityNameController.text = value;
        _draft.setActivityName(value);
        _showNameError = false;
      }),
      onCommonDutyChanged: (duty) => setState(() => _draft.setCommonDuty(duty)),
      onDutyOverrideChanged: (id, duty) =>
          setState(() => _draft.setDutyOverride(id, duty)),
      onSquadDutyChanged: (ids, duty) =>
          setState(() => _draft.setDutyForPersonnel(ids, duty)),
      onNoteChanged: (id, note) => setState(() => _draft.setNote(id, note)),
      onRemovePersonnel: (id) => setState(() {
        _draft.togglePersonnel(id);
        if (!_draft.canContinue) _draft.goToPersonnelSelection();
      }),
      onEditPersonnel: () => setState(_draft.goToPersonnelSelection),
    );
  }

  Widget _buildBottomActionBar({
    required bool isAdmin,
    required List<PersonelTableData> selectedPersonnel,
  }) {
    final isPersonnelStep = _draft.step == ActivityFormStep.personnelSelection;
    final enabled = isPersonnelStep ? _draft.canContinue : _draft.canPreview;
    final buttonLabel = isPersonnelStep
        ? 'Devam (${_draft.selectedCount})'
        : isAdmin
            ? 'Önizle ve Kaydet (${_draft.selectedCount})'
            : 'Önizle ve Onaya Gönder (${_draft.selectedCount})';

    return Material(
      elevation: 12,
      color: context.colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.readableContentWidth,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                final summary = _SelectionSummary(
                  count: _draft.selectedCount,
                  isPersonnelStep: isPersonnelStep,
                  personnel: selectedPersonnel,
                );
                final button = SizedBox(
                  height: 48,
                  width: compact ? double.infinity : 300,
                  child: FilledButton.icon(
                    key: Key(
                      isPersonnelStep
                          ? 'continue-to-details-button'
                          : 'save-activity-button',
                    ),
                    onPressed: enabled
                        ? () {
                            if (isPersonnelStep) {
                              setState(_draft.goToDetails);
                            } else {
                              _submitActivity();
                            }
                          }
                        : null,
                    icon: Icon(
                      isPersonnelStep
                          ? Icons.arrow_forward_rounded
                          : Icons.fact_check_outlined,
                    ),
                    label: Text(
                      buttonLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );

                if (compact) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      summary,
                      const SizedBox(height: 8),
                      button,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: 16),
                    button,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDiscardChanges() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Değişiklikler silinsin mi?'),
            content: const Text(
              'Seçtiğiniz personel ve faaliyet bilgileri kaydedilmedi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Devam et'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Çık'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.count,
    required this.isPersonnelStep,
    required this.personnel,
  });

  final int count;
  final bool isPersonnelStep;
  final List<PersonelTableData> personnel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: context.accentSubtleBg,
          foregroundColor: context.accentOrOlive,
          child: const Icon(Icons.groups_rounded, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count personel seçildi',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                isPersonnelStep
                    ? 'Personel seçimini tamamlayın'
                    : 'Faaliyet bilgilerini tamamlayın',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyleSecondary.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        if (isPersonnelStep && personnel.isNotEmpty) ...[
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final person in personnel.take(3))
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: CircleAvatar(
                    key: ValueKey('selected-avatar-${person.id}'),
                    radius: 13,
                    backgroundColor: context.accentSubtleBg,
                    foregroundColor: context.accentOrOlive,
                    child: Text(
                      person.adSoyad.trim().isEmpty
                          ? '?'
                          : person.adSoyad.trim()[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              if (personnel.length > 3)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    key: const Key('selected-avatar-overflow'),
                    '+${personnel.length - 3}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
