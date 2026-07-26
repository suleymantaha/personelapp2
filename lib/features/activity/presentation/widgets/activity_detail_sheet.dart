import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/add_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/edit_assignment_dialog.dart';
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
    final isAdmin = session?.isAdmin ?? true;
    final allPersonnelAsync = ref.watch(allPersonnelProvider);
    final personnelList = allPersonnelAsync.value ?? [];
    final pMap = {for (final p in personnelList) p.id: p};

    var filteredAssignments = assignments;
    if (selectedSquadId != null) {
      filteredAssignments = filteredAssignments.where((a) {
        final p = pMap[a.personelId];
        return p?.timId == selectedSquadId;
      }).toList();
    }

    final existingPersonnelIds = assignments.map((a) => a.personelId).toSet();
    final allSquadsAsync = ref.watch(allSquadsProvider);
    final squadsList = allSquadsAsync.value ?? [];
    final squadMap = {for (final s in squadsList) s.id: s.timAdi};

    final operationalAssignments =
        filteredAssignments.where((atama) {
          return DutyOrLeaveType.isOperationalDuty(atama.gorevVeyaIzin);
        }).toList()..sort((a, b) {
          final catA = MilitaryStructureHelper.getDutyCategoryOrder(
            a.gorevVeyaIzin,
          );
          final catB = MilitaryStructureHelper.getDutyCategoryOrder(
            b.gorevVeyaIzin,
          );
          if (catA != catB) return catA.compareTo(catB);

          final pA = pMap[a.personelId];
          final pB = pMap[b.personelId];

          if (catA == 10) {
            final rA = getRankWeight(pA?.rutbe ?? '');
            final rB = getRankWeight(pB?.rutbe ?? '');
            if (rA != rB) return rA.compareTo(rB);
            return (pA?.adSoyad ?? '').compareTo(pB?.adSoyad ?? '');
          }

          final timNameA =
              (pA?.timId != null && squadMap.containsKey(pA!.timId))
              ? squadMap[pA.timId]!
              : '';
          final timNameB =
              (pB?.timId != null && squadMap.containsKey(pB!.timId))
              ? squadMap[pB.timId]!
              : '';
          final rawBirlikA = (pA?.birlik != null && pA!.birlik.isNotEmpty)
              ? pA.birlik
              : timNameA;
          final rawBirlikB = (pB?.birlik != null && pB!.birlik.isNotEmpty)
              ? pB.birlik
              : timNameB;

          final wBirlikA = MilitaryStructureHelper.getSquadOrderWeight(
            rawBirlikA,
          );
          final wBirlikB = MilitaryStructureHelper.getSquadOrderWeight(
            rawBirlikB,
          );
          if (wBirlikA != wBirlikB) return wBirlikA.compareTo(wBirlikB);

          final weightA = getRankWeight(pA?.rutbe ?? '');
          final weightB = getRankWeight(pB?.rutbe ?? '');
          if (weightA != weightB) return weightA.compareTo(weightB);

          return (pA?.adSoyad ?? '').compareTo(pB?.adSoyad ?? '');
        });

    final rosterRows = <MilitaryRosterRow>[];
    for (var i = 0; i < operationalAssignments.length; i++) {
      final atama = operationalAssignments[i];
      final p = pMap[atama.personelId];
      final rutbe = p?.rutbe ?? '';
      final adSoyad = p?.adSoyad ?? 'Personel #${atama.personelId}';
      final timName = (p?.timId != null && squadMap.containsKey(p!.timId))
          ? squadMap[p.timId]!
          : '';
      final rawBirlik = (p?.birlik != null && p!.birlik.isNotEmpty)
          ? p.birlik
          : timName;
      final officialBirlik = MilitaryStructureHelper.getOfficialBirlikName(
        rawBirlik,
        duty: atama.gorevVeyaIzin,
      );

      var groupCode = 'DIGER';
      final dutyUpper = atama.gorevVeyaIzin.toUpperCase().trim();
      if (dutyUpper.contains('HAZIR KITA') || dutyUpper.contains('HAZIRKITA')) {
        groupCode = 'HAZIR_KITA';
      } else if (dutyUpper.contains('GÜLÜŞKÜR') ||
          dutyUpper.contains('GULUSKUR')) {
        groupCode = 'GULUSKUR';
      }

      final digerText = MilitaryStructureHelper.getDigerCellText(
        atama.gorevVeyaIzin,
        aciklama: atama.aciklama,
      );

      rosterRows.add(
        MilitaryRosterRow(
          sNu: i + 1,
          birligi: officialBirlik,
          rutbe: rutbe,
          adSoyad: adSoyad,
          diger: digerText,
          groupCode: groupCode,
        ),
      );
    }

    return Container(
      color: context.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Action: Add single personnel to activity
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: context.accentOrOlive,
              ),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text(
                '+ Faaliyete Personel Ekle',
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
            ),
          ),
          const SizedBox(height: 4),

          if (filteredAssignments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Bu faaliyette seçilen tim için görevlendirilmiş personel kaydı bulunmuyor.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: context.textSecondary,
                ),
              ),
            )
          else
            ...filteredAssignments.map((atama) {
              final p = pMap[atama.personelId];
              final nameText = p?.adSoyad ?? 'Personel #${atama.personelId}';
              final rutbeText = p?.rutbe ?? '';
              final birlikInfo = p?.birlik ?? '';
              final subInfo = [
                if (rutbeText.isNotEmpty) rutbeText,
                if (birlikInfo.isNotEmpty) birlikInfo,
              ].join(' • ');
              final digerNote = atama.aciklama ?? '';
              final displayName = rutbeText.isNotEmpty
                  ? '$rutbeText $nameText'
                  : nameText;

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
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subInfo.isNotEmpty)
                            Text(
                              subInfo,
                              style: TextStyle(
                                fontSize: 12,
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
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
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
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isApproved
                                ? context.approvedColor
                                : (isPending
                                      ? context.pendingColor
                                      : context.rejectedColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
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
                    const SizedBox(width: 4),
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
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('İPTAL'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.rejectedColor,
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('ÇIKAR'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final repo = ref.read(activityRepositoryProvider);
                          await repo.deleteAssignment(atama.id);
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
                      const SizedBox(width: 4),
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
                          await repo.updateAssignmentStatus(
                            atama.id,
                            AssignmentStatus.onaylandi,
                          );
                        },
                      ),
                      const SizedBox(width: 2),
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
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            }),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 15),
                  label: const Text(
                    'Metin Listesi',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () {
                    unawaited(
                      MilitaryRosterExporter.shareTextRoster(
                        faaliyetAdi: activity.faaliyetAdi,
                        tarih: activity.tarih,
                        rows: rosterRows,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accentOrOlive,
                    foregroundColor: context.onAccentOrOlive,
                  ),
                  icon: const Icon(Icons.table_chart, size: 15),
                  label: const Text(
                    'Excel Al',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () {
                    unawaited(
                      MilitaryRosterExporter.shareExcelRoster(
                        faaliyetAdi: activity.faaliyetAdi,
                        tarih: activity.tarih,
                        rows: rosterRows,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.pdfButtonBg,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 15),
                  label: const Text(
                    'PDF / Yazdır',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () {
                    unawaited(
                      PdfRosterExporter.showStylePickerAndSharePdf(
                        context,
                        faaliyetAdi: activity.faaliyetAdi,
                        tarih: activity.tarih,
                        rows: rosterRows,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
