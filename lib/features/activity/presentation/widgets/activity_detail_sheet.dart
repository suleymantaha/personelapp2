import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/domain/activity_assignment_order.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/add_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/edit_assignment_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/transfer_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/transfer_squad_dialog.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_assignment_groups.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_export_sheet.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';

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
              if (isAdmin)
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
                    final added = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AddPersonnelToActivityDialog(
                        activity: activity,
                        isAdmin: isAdmin,
                        existingPersonnelIds: existingPersonnelIds,
                      ),
                    );
                    if (added == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAdmin
                                ? 'Personel faaliyete eklendi.'
                                : 'Personel eklendi, Admin onayına gönderildi.',
                          ),
                          backgroundColor: isAdmin
                              ? context.approvedColor
                              : context.pendingColor,
                        ),
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
                onSelected: (val) {
                  if (val == 'excel') {
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
                  const PopupMenuItem(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart, size: 18),
                        SizedBox(width: 8),
                        Text('Excel Olarak Aktar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, size: 18),
                        SizedBox(width: 8),
                        Text('PDF / Yazdır'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'text',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 18),
                        SizedBox(width: 8),
                        Text('Metin Listesi Paylaş'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          if (filteredAssignments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Bu faaliyette görevlendirilmiş personel bulunmuyor.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: context.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else
            ActivityAssignmentGroups(
              assignments: filteredAssignments,
              personnelById: pMap,
              squadNames: squadMap,
              selectedSquadId: selectedSquadId,
              onTransferSquad: !isAdmin
                  ? null
                  : (squadId, squadName) async {
                      if (squadId == null) return;
                      await showTransferSquadDialog(
                        context,
                        sourceActivity: activity,
                        squadId: squadId,
                        squadName: squadName,
                      );
                    },
              onExportSelected: (selectedAssignments) async {
                final selectedRows = buildRosterRows(selectedAssignments);
                if (selectedRows.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Seçilen timlerde yazdırılabilir personel bulunamadı.',
                      ),
                    ),
                  );
                  return;
                }

                final selectedTeamIds = selectedAssignments
                    .map((a) => pMap[a.personelId]?.timId)
                    .toSet();
                final teamNames = selectedTeamIds
                    .map(
                      (id) => id == null
                          ? 'Tim Dışı'
                          : squadMap[id] ?? 'Bilinmeyen Tim',
                    )
                    .join(', ');

                final action = await showArchiveExportSheet(
                  context,
                  subtitle: '${activity.faaliyetAdi} • $teamNames',
                );
                if (action == null || !context.mounted) return;

                switch (action) {
                  case ArchiveExportType.excel:
                    await MilitaryRosterExporter.shareExcelRoster(
                      faaliyetAdi: activity.faaliyetAdi,
                      tarih: activity.tarih,
                      rows: selectedRows,
                    );
                    return;
                  case ArchiveExportType.pdf:
                    await PdfRosterExporter.showStylePickerAndSharePdf(
                      context,
                      faaliyetAdi: activity.faaliyetAdi,
                      tarih: activity.tarih,
                      rows: selectedRows,
                    );
                    return;
                  case ArchiveExportType.print:
                    await PdfRosterExporter.showStylePickerAndPrintPdf(
                      context,
                      faaliyetAdi: activity.faaliyetAdi,
                      tarih: activity.tarih,
                      rows: selectedRows,
                    );
                    return;
                  case ArchiveExportType.text:
                    await MilitaryRosterExporter.shareTextRoster(
                      faaliyetAdi: activity.faaliyetAdi,
                      tarih: activity.tarih,
                      rows: selectedRows,
                    );
                    return;
                }
              },
              onDeleteSelected: !isAdmin
                  ? null
                  : (selectedAssignments) async {
                      final selectedTeamIds = selectedAssignments
                          .map((a) => pMap[a.personelId]?.timId)
                          .toSet();
                      final teamNames = selectedTeamIds
                          .map(
                            (id) => id == null
                                ? 'Tim Dışı'
                                : squadMap[id] ?? 'Bilinmeyen Tim',
                          )
                          .join(', ');
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Timleri Faaliyetten Sil'),
                          content: Text(
                            '$teamNames timlerindeki '
                            '${selectedAssignments.length} personel bu '
                            'faaliyetten çıkarılacaktır. Emin misiniz?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('İPTAL'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: context.rejectedColor,
                              ),
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('TİMLERİ SİL'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !context.mounted) return;
                      final deleted = await ref
                          .read(activityRepositoryProvider)
                          .deleteAssignments(
                            selectedAssignments.map((a) => a.id),
                            actor: session!,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$deleted personel faaliyetten çıkarıldı.',
                            ),
                          ),
                        );
                      }
                    },
              assignmentBuilder: (atama) {
                final p = pMap[atama.personelId];
                final nameText = p?.adSoyad ?? 'Personel #${atama.personelId}';
                final rutbeText = p?.rutbe ?? '';
                final birlikInfo = p?.birlik ?? '';
                final subInfo = [
                  if (rutbeText.isNotEmpty) rutbeText,
                  if (birlikInfo.isNotEmpty) birlikInfo,
                ].join(' • ');
                final digerNote = atama.aciklama ?? '';
                final displayName =
                    rutbeText.isNotEmpty ? '$rutbeText $nameText' : nameText;

                final isPending = atama.durum == AssignmentStatus.beklemede;
                final isApproved = atama.durum == AssignmentStatus.onaylandi;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: context.colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (subInfo.isNotEmpty)
                              Text(
                                subInfo,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textSecondary,
                                ),
                              ),
                            if (digerNote.isNotEmpty)
                              Text(
                                'Not: $digerNote',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: context.accentOrOlive,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isApproved
                              ? context.approvedColor.withValues(alpha: 0.12)
                              : (isPending
                                  ? context.pendingColor.withValues(
                                      alpha: 0.25,
                                    )
                                  : context.rejectedBgColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPending
                              ? '${atama.gorevVeyaIzin} • BEKLİYOR'
                              : atama.gorevVeyaIzin,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isApproved
                                ? context.approvedColor
                                : (isPending
                                    ? context.pendingColor
                                    : context.rejectedColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      if (isAdmin)
                        IconButton(
                          key: Key('personnel-transfer-btn-${atama.id}'),
                          icon: Icon(
                            Icons.swap_horiz_rounded,
                            color: context.accentOrOlive,
                            size: 18,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: '$displayName kişisini başka karta taşı',
                          onPressed: () async {
                            await showTransferPersonnelDialog(
                              context,
                              sourceActivity: activity,
                              assignment: atama,
                              personnelDisplayName: displayName,
                            );
                          },
                        ),
                      if (isAdmin)
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: context.blueGreyColor,
                            size: 18,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Düzenle',
                          onPressed: () async {
                            final updated = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => EditAssignmentDialog(
                                assignment: atama,
                                personnelName: displayName,
                                isAdmin: isAdmin,
                              ),
                            );
                            if (updated == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAdmin
                                        ? 'Görev güncellendi.'
                                        : 'Görev değişikliği kaydedildi, Admin onayına gönderildi.',
                                  ),
                                  backgroundColor: isAdmin
                                      ? context.approvedColor
                                      : context.pendingColor,
                                ),
                              );
                            }
                          },
                        ),
                      if (isAdmin)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: context.rejectedColor,
                            size: 18,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Çıkar',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Personeli Görevden Çıkar'),
                                content: Text(
                                  '$displayName adlı personel ${activity.faaliyetAdi} faaliyetinden çıkarılacaktır. Emin misiniz?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('İPTAL'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.rejectedColor,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('ÇIKAR'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final repo = ref.read(activityRepositoryProvider);
                              await repo.deleteAssignment(
                                atama.id,
                                actor: session!,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$displayName faaliyetten çıkarıldı.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      if (isAdmin && isPending) ...[
                        IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: context.approvedColor,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Onayla',
                          onPressed: () async {
                            final repo = ref.read(activityRepositoryProvider);
                            final result = await repo.approveAssignment(
                              atama.id,
                              actor: session!,
                            );
                            if (context.mounted && result.blockedCount > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Onaylanamadı: '
                                    '${result.conflictDescriptions.join(', ')}',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: context.rejectedColor,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Reddet',
                          onPressed: () async {
                            final repo = ref.read(activityRepositoryProvider);
                            await repo.updateAssignmentStatus(
                              atama.id,
                              AssignmentStatus.reddedildi,
                              actor: session!,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
