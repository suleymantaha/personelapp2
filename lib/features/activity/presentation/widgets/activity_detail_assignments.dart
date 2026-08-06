part of 'activity_detail_sheet.dart';

extension _ActivityDetailAssignments on ActivityAssignmentDetails {
  List<Widget> _buildAssignmentContent({
    required BuildContext context,
    required WidgetRef ref,
    required UserSessionState? session,
    required bool isAdmin,
    required List<FaaliyetPersonelAtamaTableData> filteredAssignments,
    required Map<int, PersonelTableData> personnelById,
    required Map<int, String> squadNames,
    required List<MilitaryRosterRow> Function(
      Iterable<FaaliyetPersonelAtamaTableData> assignments,
    ) buildRosterRows,
  }) {
    final pMap = personnelById;
    final squadMap = squadNames;
    return [
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
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('İPTAL'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: context.rejectedColor,
                          ),
                          onPressed: () => Navigator.pop(dialogContext, true),
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
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: name (always full width) + status chip
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          nameText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? context.approvedColor.withValues(alpha: 0.12)
                                : (isPending
                                    ? context.pendingColor
                                        .withValues(alpha: 0.22)
                                    : context.rejectedBgColor),
                            borderRadius: BorderRadius.circular(8),
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
                      ),
                    ],
                  ),
                  // Row 2: rütbe + birlik bilgisi
                  if (subInfo.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subInfo,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                  // Row 3: not (varsa)
                  if (digerNote.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Not: $digerNote',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: context.accentOrOlive,
                      ),
                    ),
                  ],
                  // Admin actions satırı
                  if (isAdmin) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isPending) ...[
                          // Onayla ikonu
                          SizedBox(
                            width: 32,
                            height: 28,
                            child: IconButton(
                              icon: Icon(
                                Icons.check_circle,
                                color: context.approvedColor,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Onayla',
                              onPressed: () async {
                                final repo =
                                    ref.read(activityRepositoryProvider);
                                final result = await repo.approveAssignment(
                                  atama.id,
                                  actor: session!,
                                );
                                if (context.mounted &&
                                    result.blockedCount > 0) {
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
                          ),
                          // Reddet ikonu
                          SizedBox(
                            width: 32,
                            height: 28,
                            child: IconButton(
                              icon: Icon(
                                Icons.cancel,
                                color: context.rejectedColor,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Reddet',
                              onPressed: () async {
                                final repo =
                                    ref.read(activityRepositoryProvider);
                                await repo.updateAssignmentStatus(
                                  atama.id,
                                  AssignmentStatus.reddedildi,
                                  actor: session!,
                                );
                              },
                            ),
                          ),
                        ],
                        // Düzenle + Sil → 3-nokta menü
                        PopupMenuButton<_AssignmentAction>(
                          icon: Icon(
                            Icons.more_horiz,
                            color: context.textSecondary,
                            size: 18,
                          ),
                          tooltip: 'İşlemler',
                          padding: EdgeInsets.zero,
                          elevation: 5,
                          shadowColor: context.shadowColor,
                          surfaceTintColor: context.colorScheme.surface,
                          shape: modernPopupShape(context),
                          constraints: const BoxConstraints(
                            minWidth: 290,
                            maxWidth: 330,
                          ),
                          onSelected: (action) async {
                            switch (action) {
                              case _AssignmentAction.edit:
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
                              case _AssignmentAction.transfer:
                                await showTransferPersonnelDialog(
                                  context,
                                  sourceActivity: activity,
                                  assignment: atama,
                                  personnelDisplayName: displayName,
                                );
                              case _AssignmentAction.delete:
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title:
                                        const Text('Personeli Görevden Çıkar'),
                                    content: Text(
                                      '$displayName adlı personel '
                                      '${activity.faaliyetAdi} '
                                      'faaliyetinden çıkarılacaktır. '
                                      'Emin misiniz?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('İPTAL'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              context.rejectedColor,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('ÇIKAR'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final repo =
                                      ref.read(activityRepositoryProvider);
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
                            }
                          },
                          itemBuilder: (ctx) => [
                            ModernMenuHeader<_AssignmentAction>(
                              title: 'Atama İşlemleri',
                              subtitle: displayName,
                              icon: Icons.assignment_ind_outlined,
                            ),
                            const PopupMenuDivider(),
                            ModernPopupMenuItem(
                              option: const ModernActionOption(
                                value: _AssignmentAction.edit,
                                title: 'Düzenle',
                                subtitle: 'Görev veya izin bilgisini değiştir',
                                icon: Icons.edit_outlined,
                              ),
                            ),
                            ModernPopupMenuItem(
                              option: const ModernActionOption(
                                value: _AssignmentAction.transfer,
                                title: 'Başka karta taşı',
                                subtitle: 'Personeli farklı faaliyete aktar',
                                icon: Icons.swap_horiz_rounded,
                              ),
                            ),
                            const PopupMenuDivider(),
                            ModernPopupMenuItem(
                              option: const ModernActionOption(
                                value: _AssignmentAction.delete,
                                title: 'Faaliyetten çıkar',
                                subtitle: 'Personelin bu atamasını kaldır',
                                icon: Icons.person_remove_outlined,
                                isDestructive: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
    ];
  }
}
