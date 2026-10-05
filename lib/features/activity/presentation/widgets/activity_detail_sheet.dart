import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/domain/activity_assignment_order.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/add_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/previous_day_excel_picker.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/edit_assignment_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/transfer_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/transfer_squad_dialog.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_assignment_groups.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_export_sheet.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/combined_heybet_excel_service.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_image_import_service.dart';

part 'activity_detail_assignments.dart';

class ActivityAssignmentDetails extends ConsumerWidget {
  const ActivityAssignmentDetails({
    required this.activity,
    required this.assignments,
    this.selectedSquadId,
    super.key,
  });

  final GunlukFaaliyetTableData activity;
  final List<FaaliyetPersonelAtamaTableData> assignments;
  final int? selectedSquadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;
    final allPersonnelAsync = ref.watch(allPersonnelProvider);
    final personnelList = allPersonnelAsync.value ?? [];
    final pMap = {for (final p in personnelList) p.id: p};

    var filteredAssignments = assignments;
    if (!isAdmin) {
      if (session?.timId == null) {
        filteredAssignments = const <FaaliyetPersonelAtamaTableData>[];
      } else {
        filteredAssignments = filteredAssignments.where((a) {
          final person = pMap[a.personelId];
          return person?.timId == session!.timId;
        }).toList();
      }
    }

    if (selectedSquadId != null) {
      filteredAssignments = filteredAssignments.where((a) {
        final p = pMap[a.personelId];
        return p?.timId == selectedSquadId;
      }).toList();
    }

    final existingPersonnelIds =
        filteredAssignments.map((a) => a.personelId).toSet();
    final allSquadsAsync = ref.watch(allSquadsProvider);
    final squadsList = allSquadsAsync.value ?? [];
    final squadMap = {for (final s in squadsList) s.id: s.timAdi};

    List<MilitaryRosterRow> buildRosterRows(
      Iterable<FaaliyetPersonelAtamaTableData> source,
    ) {
      final operationalAssignments = orderAssignmentsForExport(
        source.where(
          (atama) => DutyOrLeaveType.isOperationalDuty(atama.gorevVeyaIzin),
        ),
        pMap,
        squadMap,
      );

      return [
        for (var i = 0; i < operationalAssignments.length; i++)
          () {
            final atama = operationalAssignments[i];
            final p = pMap[atama.personelId];
            final timName = (p?.timId != null && squadMap.containsKey(p!.timId))
                ? squadMap[p.timId]!
                : '';
            return MilitaryRosterRow(
              sNu: i + 1,
              birligi: MilitaryStructureHelper.getRosterBirlikName(
                timName: timName,
                birlik: p?.birlik ?? '',
                duty: atama.gorevVeyaIzin,
              ),
              rutbe: p?.rutbe ?? '',
              adSoyad: p?.adSoyad ?? 'Personel #${atama.personelId}',
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

    final rosterRows = buildRosterRows(filteredAssignments);

    Future<void> shareSeparateCombinedExcel() async {
      final visiblePersonnel = {
        for (final p in personnelList)
          if ((isAdmin ||
                  (session?.timId != null && p.timId == session!.timId)) &&
              (selectedSquadId == null || p.timId == selectedSquadId))
            p.id: p,
      };
      final service = CombinedHeybetExcelService(ref.read(databaseProvider));
      final previousActivities = await service.listPreviousActivities(activity);
      if (!context.mounted) return;
      final selectedIds = await showDialog<Set<int>>(
        context: context,
        builder: (_) => PreviousDayExcelPicker(activities: previousActivities),
      );
      if (selectedIds == null || selectedIds.isEmpty || !context.mounted) {
        return;
      }
      final rows = await service.build(
        activity: activity,
        selectedPreviousActivityIds: selectedIds,
        currentRows: rosterRows,
        personnelById: visiblePersonnel,
        squadNames: squadMap,
      );
      if (!context.mounted) return;
      if (!await confirmCombinedExcelPreview(context, rows) ||
          !context.mounted) {
        return;
      }
      await MilitaryRosterExporter.shareExcelRoster(
        faaliyetAdi:
            '${activity.faaliyetAdi} + Seçilen Önceki Gün Faaliyetleri',
        tarih: activity.tarih,
        rows: rows,
        mergeCells: false,
      );
    }

    return Container(
      color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Add Personnel & Single Activity Quick Export Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (session != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: context.accentOrOlive,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: const Text(
                    '+ Personel Ekle',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                              title: const Text('Tek Personel Ekle'),
                              subtitle: const Text(
                                'Kayıtlı personelden bir kişi seçin',
                              ),
                              onTap: () =>
                                  Navigator.of(sheetContext).pop('single'),
                            ),
                            ListTile(
                              key: const Key(
                                'activity-add-bulk-personnel-option',
                              ),
                              leading: const Icon(
                                Icons.content_paste_go_rounded,
                              ),
                              title: const Text('Metinden Toplu Ekle'),
                              subtitle: const Text(
                                'Listeyi tam önizleme ve hata kontrolüyle aktar',
                              ),
                              onTap: () =>
                                  Navigator.of(sheetContext).pop('bulk'),
                            ),
                            ListTile(
                              key: const Key(
                                'activity-add-image-personnel-option',
                              ),
                              leading: const Icon(Icons.image_search_rounded),
                              title: const Text('Görselden Toplu Ekle'),
                              subtitle: const Text(
                                'Personel listesini görselden okuyup bu karta ekle',
                              ),
                              onTap: () =>
                                  Navigator.of(sheetContext).pop('image'),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (!context.mounted || action == null) return;
                    if (action == 'image') {
                      final service = RosterImageImportService();
                      if (!service.isSupportedPlatform) {
                        AppNotifications.warning(
                          'Görselden aktarım Android ve iOS cihazlarda kullanılabilir.',
                        );
                        return;
                      }
                      try {
                        final imageResult = await service.pickAndExtract();
                        if (imageResult == null || !context.mounted) return;

                        final db = ref.read(databaseProvider);
                        final activityRepo =
                            ref.read(activityRepositoryProvider);
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => BulkImportDialog(
                            database: db,
                            activityRepository: activityRepo,
                            initialText: imageResult.bulkImportText,
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
                        AppNotifications.error('Görsel okunamadı: $error');
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

                    final added = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AddPersonnelToActivityDialog(
                        activity: activity,
                        isAdmin: isAdmin,
                        existingPersonnelIds: existingPersonnelIds,
                      ),
                    );
                    if (added == true && context.mounted) {
                      AppNotifications.approvalResult(
                        isAdmin
                            ? 'Personel faaliyete eklendi.'
                            : 'Personel eklendi, Admin onayına gönderildi.',
                        pendingApproval: !isAdmin,
                      );
                    }
                  },
                )
              else
                const SizedBox.shrink(),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  color: context.textSecondary,
                  size: 20,
                ),
                tooltip: 'Bu Faaliyeti Dışa Aktar',
                elevation: 5,
                shadowColor: context.shadowColor,
                surfaceTintColor: context.colorScheme.surface,
                shape: modernPopupShape(context),
                constraints: const BoxConstraints(minWidth: 290, maxWidth: 330),
                onSelected: (val) {
                  if (val == 'combinedExcel') {
                    unawaited(shareSeparateCombinedExcel());
                  } else if (val == 'excel') {
                    unawaited(
                      MilitaryRosterExporter.shareExcelRoster(
                        faaliyetAdi: activity.faaliyetAdi,
                        tarih: activity.tarih,
                        rows: rosterRows,
                      ),
                    );
                  } else if (val == 'pdf') {
                    unawaited(
                      PdfRosterExporter.showStylePickerAndSharePdf(
                        context,
                        faaliyetAdi: activity.faaliyetAdi,
                        tarih: activity.tarih,
                        rows: rosterRows,
                      ),
                    );
                  } else if (val == 'text') {
                    unawaited(
                      MilitaryRosterExporter.shareTextRoster(
                        faaliyetAdi: activity.faaliyetAdi,
                        tarih: activity.tarih,
                        rows: rosterRows,
                      ),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  const ModernMenuHeader<String>(
                    title: 'Dışa Aktar',
                    subtitle: 'Faaliyet listesini paylaş veya yazdır',
                    icon: Icons.ios_share_rounded,
                  ),
                  const PopupMenuDivider(),
                  if (CombinedHeybetExcelService.isHeybet(activity.faaliyetAdi))
                    ModernPopupMenuItem(
                      option: const ModernActionOption(
                        value: 'combinedExcel',
                        title: 'Önceki Gün Kartlarıyla Ayrı Excel',
                        subtitle:
                            'Önceki günün kartlarını seçerek ayrı dosyada paylaş',
                        icon: Icons.table_chart_outlined,
                      ),
                    ),
                  ModernPopupMenuItem(
                    option: const ModernActionOption(
                      value: 'excel',
                      title: 'Excel’e aktar',
                      subtitle: 'Hesap tablosu olarak paylaş',
                      icon: Icons.table_chart_outlined,
                    ),
                  ),
                  ModernPopupMenuItem(
                    option: const ModernActionOption(
                      value: 'pdf',
                      title: 'PDF / Yazdır',
                      subtitle: 'PDF oluştur veya doğrudan yazdır',
                      icon: Icons.picture_as_pdf_outlined,
                    ),
                  ),
                  ModernPopupMenuItem(
                    option: const ModernActionOption(
                      value: 'text',
                      title: 'Metin olarak paylaş',
                      subtitle: 'Mesajlaşma uygulamaları için hazırla',
                      icon: Icons.share_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          ..._buildAssignmentContent(
            context: context,
            ref: ref,
            session: session,
            isAdmin: isAdmin,
            filteredAssignments: filteredAssignments,
            personnelById: pMap,
            squadNames: squadMap,
            buildRosterRows: buildRosterRows,
          ),
        ],
      ),
    );
  }
}

enum _AssignmentAction { edit, transfer, delete }
