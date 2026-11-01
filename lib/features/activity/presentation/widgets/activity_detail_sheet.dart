import 'roster_format_actions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/domain/activity_assignment_order.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/add_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/reassign_existing_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/edit_assignment_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/transfer_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/transfer_squad_dialog.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_assignment_groups.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_image_import_service.dart';
import 'package:personelapp2/features/temgundrap/data/temgundrap_repository.dart';
import 'package:personelapp2/features/temgundrap/domain/services/temgundrap_activity_converter.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_defaults.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';

part 'activity_detail_assignments.dart';

class ActivityAssignmentDetails extends ConsumerWidget {
  const ActivityAssignmentDetails({
    required this.activity,
    required this.assignments,
    this.selectedSquadId,
    this.usePersistentToolbar = false,
    this.selectionActive = false,
    super.key,
  });

  final GunlukFaaliyetTableData activity;
  final List<FaaliyetPersonelAtamaTableData> assignments;
  final int? selectedSquadId;
  final bool usePersistentToolbar;
  final bool selectionActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;
    final allPersonnelAsync = ref.watch(historicalPersonnelProvider);
    final personnelList = allPersonnelAsync.value ?? [];
    final pMap = {for (final p in personnelList) p.id: p};

    var filteredAssignments = assignments;
    if (!isAdmin) {
      if (session?.timId == null) {
        filteredAssignments = const <FaaliyetPersonelAtamaTableData>[];
      } else {
        filteredAssignments = filteredAssignments.where((a) {
          final authority = ref.watch(commanderAuthorityProvider).valueOrNull;
          return authority != null && a.gorevTimId == authority;
        }).toList();
      }
    }

    if (selectedSquadId != null) {
      filteredAssignments = filteredAssignments.where((a) {
        return a.gorevTimId == selectedSquadId;
      }).toList();
    }

    final existingPersonnelIds =
        filteredAssignments.map((a) => a.personelId).toSet();
    final allSquadsAsync = ref.watch(allSquadsProvider);
    final squadsList = allSquadsAsync.value ?? [];
    final squadMap = {for (final s in squadsList) s.id: s.timAdi};

    List<MilitaryRosterRow> buildRosterRows(
      Iterable<FaaliyetPersonelAtamaTableData> source, {
      Map<int, PersonelTableData>? freshPersonnel,
    }) {
      final rosterPersonnel = freshPersonnel ?? pMap;
      final operationalAssignments = orderAssignmentsForExport(
        source.where(
          (atama) => DutyOrLeaveType.isApprovedOperationalDuty(
            atama.gorevVeyaIzin,
            atama.durum,
          ),
        ),
        rosterPersonnel,
        squadMap,
        squadOrders: {for (final s in squadsList) s.id: s.sortOrder},
      );

      return [
        for (var i = 0; i < operationalAssignments.length; i++)
          () {
            final atama = operationalAssignments[i];
            final p = rosterPersonnel[atama.personelId];
            final timName = atama.gorevTimAdi ??
                context.l10n.activityDetailUnknownSquadHistory;
            return MilitaryRosterRow(
              sNu: i + 1,
              personelId: atama.personelId,
              birligi: MilitaryStructureHelper.getRosterBirlikName(
                timName: timName,
                birlik: p?.birlik ?? '',
                duty: atama.gorevVeyaIzin,
              ),
              rutbe: p?.rutbe ?? '',
              adSoyad: p?.adSoyad ??
                  context.l10n
                      .activityDetailPersonnelFallback(atama.personelId),
              diger: MilitaryStructureHelper.getDigerCellText(
                atama.gorevVeyaIzin,
                aciklama: atama.aciklama,
              ),
              groupCode: MilitaryStructureHelper.getRosterGroupCode(
                atama.gorevVeyaIzin,
              ),
            );
          }(),
      ];
    }

    Future<List<MilitaryRosterRow>> loadCurrentRows(
      Iterable<FaaliyetPersonelAtamaTableData> selected,
    ) async {
      final actor = ref.read(userSessionProvider);
      if (actor == null) throw StateError(context.l10n.authSessionFailed);
      final snapshot =
          await ref.read(activityRepositoryProvider).loadOutputSnapshot(
                actor: actor,
                sources: [activity],
                selectedAssignmentIds: selected.map((a) => a.id),
                selectedSquadId: selectedSquadId,
              );
      return buildRosterRows(snapshot.assignments,
          freshPersonnel: snapshot.personnelMap);
    }

    Future<void> exportActivity() async {
      final selection = List<FaaliyetPersonelAtamaTableData>.unmodifiable(
          filteredAssignments);
      try {
        await showRosterFormatActions(context,
            name: activity.faaliyetAdi,
            date: activity.tarih,
            subtitle: '${activity.tarih} · ${activity.faaliyetAdi} · '
                '${buildRosterRows(selection).length} onaylı görev personeli',
            loadRows: () => loadCurrentRows(selection));
      } catch (error) {
        if (context.mounted) {
          AppNotifications.error(
              context.l10n.rosterOutputExportError('$error'));
        }
      }
    }

    final personnelAction = session == null
        ? null
        : TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: context.accentOrOlive,
              backgroundColor: context.accentOrOlive.withValues(alpha: 0.07),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 44),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
            label: Text(
              context.l10n.activityDetailAddPersonnelButton,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            onPressed: () async {
              final action = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                builder: (sheetContext) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        key: const Key(
                          'activity-add-single-personnel-option',
                        ),
                        leading: const Icon(
                          Icons.person_add_alt_1_rounded,
                        ),
                        title: Text(context.l10n.activityDetailAddSingleOption),
                        subtitle: Text(
                          context.l10n.activityDetailAddSingleOptionSubtitle,
                        ),
                        onTap: () => Navigator.of(sheetContext).pop('single'),
                      ),
                      if (isAdmin && filteredAssignments.isNotEmpty)
                        ListTile(
                          key: const Key('activity-reassign-existing-option'),
                          leading: const Icon(Icons.assignment_ind_outlined),
                          title: const Text('Mevcut personele görev ata'),
                          subtitle: const Text(
                            'Eklenmiş personeli seçerek görevini değiştir',
                          ),
                          onTap: () =>
                              Navigator.of(sheetContext).pop('reassign'),
                        ),
                      ListTile(
                        key: const Key(
                          'activity-add-bulk-personnel-option',
                        ),
                        leading: const Icon(
                          Icons.content_paste_go_rounded,
                        ),
                        title: Text(context.l10n.activityDetailAddBulkOption),
                        subtitle: Text(
                          context.l10n.activityDetailAddBulkOptionSubtitle,
                        ),
                        onTap: () => Navigator.of(sheetContext).pop('bulk'),
                      ),
                      ListTile(
                        key: const Key(
                          'activity-add-image-personnel-option',
                        ),
                        leading: const Icon(Icons.image_search_rounded),
                        title: Text(context.l10n.activityDetailAddImageOption),
                        subtitle: Text(
                          context.l10n.activityDetailAddImageOptionSubtitle,
                        ),
                        onTap: () => Navigator.of(sheetContext).pop('image'),
                      ),
                    ],
                  ),
                ),
              );
              if (!context.mounted || action == null) return;
              if (action == 'reassign') {
                if (!isAdmin || filteredAssignments.isEmpty) return;
                final updated = await Navigator.of(
                  context,
                  rootNavigator: true,
                ).push<bool>(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => ReassignExistingPersonnelDialog(
                      activity: activity,
                      assignments: filteredAssignments,
                      personnelById: pMap,
                    ),
                  ),
                );
                if (updated == true && context.mounted) {
                  ref.invalidate(filteredActivitiesProvider);
                  ref.invalidate(pendingAssignmentsProvider);
                }
                return;
              }
              if (action == 'image') {
                final service = RosterImageImportService();
                if (!service.isSupportedPlatform) {
                  AppNotifications.warning(
                    context.l10n.activityDetailImagePlatformWarning,
                  );
                  return;
                }
                try {
                  final imageResult = await service.pickAndExtract();
                  if (imageResult == null || !context.mounted) return;

                  final db = ref.read(databaseProvider);
                  final activityRepo = ref.read(
                    activityRepositoryProvider,
                  );
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => BulkImportDialog(
                      database: db,
                      activityRepository: activityRepo,
                      initialText: imageResult.bulkImportText,
                      isImageImport: true,
                      targetActivity: activity,
                    ),
                  );
                  if (result == true && context.mounted) {
                    ref.invalidate(activityRepositoryProvider);
                    ref.invalidate(filteredActivitiesProvider);
                    ref.invalidate(pendingAssignmentsProvider);
                  }
                } on RosterImageImportUnsupportedException catch (error) {
                  AppNotifications.warning(error.toString());
                } on RosterImageImportNoNamesException catch (error) {
                  AppNotifications.warning(error.toString());
                } on Object catch (error) {
                  if (context.mounted) {
                    AppNotifications.error(
                      context.l10n.activityDetailImageReadError(
                        error.toString(),
                      ),
                    );
                  }
                }
                return;
              }
              if (action == 'bulk') {
                final db = ref.read(databaseProvider);
                final activityRepo = ref.read(activityRepositoryProvider);
                final result = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => BulkImportDialog(
                    database: db,
                    activityRepository: activityRepo,
                    targetActivity: activity,
                  ),
                );
                if (result == true && context.mounted) {
                  ref.invalidate(activityRepositoryProvider);
                  ref.invalidate(filteredActivitiesProvider);
                  ref.invalidate(pendingAssignmentsProvider);
                }
                return;
              }

              final added = await Navigator.of(
                context,
                rootNavigator: true,
              ).push<bool>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (ctx) => AddPersonnelToActivityDialog(
                    activity: activity,
                    isAdmin: isAdmin,
                    existingPersonnelIds: existingPersonnelIds,
                  ),
                ),
              );
              if (added == true && context.mounted) {
                AppNotifications.approvalResult(
                  isAdmin
                      ? context.l10n.activityDetailPersonnelAdded
                      : context.l10n.activityDetailPersonnelAddedAdminPending,
                  pendingApproval: !isAdmin,
                );
              }
            },
          );

    return Container(
      decoration: BoxDecoration(
        color: context.accentOrOlive.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '${filteredAssignments.map((a) => a.gorevTimId).toSet().length} tim · '
              '${filteredAssignments.map((a) => a.personelId).toSet().length} personel',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._buildAssignmentContent(
            context: context,
            ref: ref,
            personnelAction: personnelAction,
            session: session,
            isAdmin: isAdmin,
            filteredAssignments: filteredAssignments,
            personnelById: pMap,
            squadNames: squadMap,
            squadOrders: {for (final s in squadsList) s.id: s.sortOrder},
            buildRosterRows: buildRosterRows,
            loadCurrentRows: loadCurrentRows,
          ),
          if (!selectionActive) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
                key: const Key('activity-detail-export'),
                onPressed: filteredAssignments.isEmpty ? null : exportActivity,
                icon: const Icon(Icons.ios_share),
                label: const Text('Faaliyetin çıktısını al')),
            TextButton.icon(
                key: const Key('activity-detail-report'),
                onPressed: filteredAssignments.isEmpty
                    ? null
                    : () async {
                        try {
                          await _exportSelectedTemgundrap(
                              context, ref, filteredAssignments);
                        } catch (error) {
                          if (context.mounted) AppNotifications.error('$error');
                        }
                      },
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('TEMGÜNDRAP taslağı oluştur')),
          ],
        ],
      ),
    );
  }
}

enum _AssignmentAction { edit, transfer, delete }
