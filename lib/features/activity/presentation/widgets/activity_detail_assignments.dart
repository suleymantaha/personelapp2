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
    )
    buildRosterRows,
    required Future<List<MilitaryRosterRow>> Function(Iterable<FaaliyetPersonelAtamaTableData>) loadCurrentRows,
  }) {
    final pMap = personnelById;
    final squadMap = squadNames;
    return [
      if (filteredAssignments.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            context.l10n.activityDetailNoPersonnelAssigned,
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
          onTransferSquad:
              !isAdmin
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
              AppNotifications.info(
                context.l10n.activityDetailNoPrintablePersonnel,
              );
              return;
            }

            final selectedTeamIds =
                selectedAssignments.map((a) => a.gorevTimId).toSet();
            final teamNames = selectedTeamIds
                .map(
                  (id) =>
                      id == null
                          ? context.l10n.activityDetailOutSquad
                          : squadMap[id] ?? context.l10n.activityDetailUnknownSquad,
                )
                .join(', ');

            final action = await showArchiveExportSheet(
              context,
              subtitle: '${activity.faaliyetAdi} • $teamNames',
            );
            if (action == null || !context.mounted) return;

            try {
            final currentRows = await loadCurrentRows(selectedAssignments);
            if (!context.mounted || currentRows.isEmpty) return;
            switch (action.type) {
              case ArchiveExportType.excel:
                await MilitaryRosterExporter.shareExcelRoster(
                  faaliyetAdi: activity.faaliyetAdi,
                  tarih: activity.tarih,
                  rows: currentRows,
                  timeRange: action.timeRange,
                );
                return;
              case ArchiveExportType.pdf:
                await PdfRosterExporter.showStylePickerAndSharePdf(
                  context,
                  faaliyetAdi: activity.faaliyetAdi,
                  tarih: activity.tarih,
                  rows: currentRows,
                  loadRows: () => loadCurrentRows(selectedAssignments),
                  timeRange: action.timeRange,
                );
                return;
              case ArchiveExportType.print:
                await PdfRosterExporter.showStylePickerAndPrintPdf(
                  context,
                  faaliyetAdi: activity.faaliyetAdi,
                  tarih: activity.tarih,
                  rows: currentRows,
                  loadRows: () => loadCurrentRows(selectedAssignments),
                  timeRange: action.timeRange,
                );
                return;
              case ArchiveExportType.text:
                await MilitaryRosterExporter.shareTextRoster(
                  faaliyetAdi: activity.faaliyetAdi,
                  tarih: activity.tarih,
                  rows: currentRows,
                  timeRange: action.timeRange,
                );
                return;
              case ArchiveExportType.temgundrap:
                final db = ref.read(databaseProvider);
                final personnel = await db.select(db.personelTable).get();
                final pMap = {for (final p in personnel) p.id: p};
                final op = TemgundrapActivityConverter.convert(
                  activity: activity,
                  assignments: selectedAssignments,
                  personnelMap: pMap,
                );
                final repo = TemgundrapRepository();
                final defaults = await repo.getApproverDefaults();
                final docDate = DateTime.tryParse(activity.tarih) ?? DateTime.now();
                final draft = TemgundrapDocument(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  date: docDate,
                  unitTitle: defaults.unitTitle.isNotEmpty
                      ? defaults.unitTitle
                      : defaultTemgundrapUnitTitle,
                  approverName: defaults.name,
                  approverRank: defaults.rank,
                  approverDuty: defaults.duty,
                  operations: [op],
                  isDraft: true,
                  updatedAt: DateTime.now(),
                );
                if (context.mounted) {
                  await AppNavigator.toTemgundrapForm(context, document: draft, date: docDate);
                }
                return;
            }
            } catch (error) {
              if (context.mounted) {
                AppNotifications.error(
                  context.l10n.rosterOutputExportError(error.toString()),
                );
              }
            }
          },
          onDeleteSelected:
              !isAdmin
                  ? null
                  : (selectedAssignments) async {
                    final selectedTeamIds =
                        selectedAssignments.map((a) => a.gorevTimId).toSet();
                    final teamNames = selectedTeamIds
                        .map(
                          (id) =>
                              id == null
                                  ? context.l10n.activityDetailOutSquad
                                  : squadMap[id] ??
                                      context.l10n.activityDetailUnknownSquad,
                        )
                        .join(', ');
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (dialogContext) => AlertDialog(
                            title: Text(
                              context.l10n.activityDetailDeleteSquadsTitle,
                            ),
                            content: Text(
                              context.l10n.activityDetailDeleteSquadsConfirm(
                                teamNames,
                                selectedAssignments.length,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.pop(dialogContext, false),
                                child: Text(context.l10n.commonCancel),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: context.rejectedColor,
                                ),
                                onPressed:
                                    () => Navigator.pop(dialogContext, true),
                                child: Text(
                                  context.l10n.activityDetailDeleteSquadsAction,
                                ),
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
                      AppNotifications.info(
                        context.l10n.activityDetailPersonnelRemovedCount(
                          deleted,
                        ),
                      );
                    }
                  },
          assignmentBuilder: (atama) {
            final p = pMap[atama.personelId];
            final nameText = p?.adSoyad ??
                context.l10n.activityDetailPersonnelFallback(atama.personelId);
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
                            color:
                                isApproved
                                    ? context.approvedColor.withValues(
                                      alpha: 0.12,
                                    )
                                    : (isPending
                                        ? context.pendingColor.withValues(
                                          alpha: 0.22,
                                        )
                                        : context.rejectedBgColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPending
                                ? context.l10n.activityDetailDutyPending(
                                  atama.gorevVeyaIzin,
                                )
                                : atama.gorevVeyaIzin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  isApproved
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
                      context.l10n.activityDetailNoteLabel(digerNote),
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
                              tooltip: context.l10n.commonApproveTooltip,
                              onPressed: () async {
                                final repo = ref.read(
                                  activityRepositoryProvider,
                                );
                                final result = await repo.approveAssignment(
                                  atama.id,
                                  actor: session!,
                                );
                                if (context.mounted &&
                                    result.blockedCount > 0) {
                                  AppNotifications.error(
                                    context.l10n.activityDetailApproveBlocked(
                                      result.conflictDescriptions.join(', '),
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
                              tooltip: context.l10n.commonRejectTooltip,
                              onPressed: () async {
                                final repo = ref.read(
                                  activityRepositoryProvider,
                                );
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
                          tooltip: context.l10n.commonActionsTooltip,
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
                                final updated = await showEditAssignmentModal(
                                  context: context,
                                  assignment: atama,
                                  personnelName: displayName,
                                  isAdmin: isAdmin,
                                );
                                if (updated == true && context.mounted) {
                                  AppNotifications.approvalResult(
                                    isAdmin
                                        ? context.l10n.activityDetailDutyUpdated
                                        : context.l10n.activityDetailDutyUpdatePending,
                                    pendingApproval: !isAdmin,
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
                                  builder:
                                      (ctx) => AlertDialog(
                                        title: Text(
                                          context.l10n.activityDetailRemovePersonnelTitle,
                                        ),
                                        content: Text(
                                          context.l10n.activityDetailRemovePersonnelConfirm(
                                            displayName,
                                            activity.faaliyetAdi,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  ctx,
                                                ).pop(false),
                                            child: Text(context.l10n.commonCancel),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  context.rejectedColor,
                                            ),
                                            onPressed:
                                                () =>
                                                    Navigator.of(ctx).pop(true),
                                            child: Text(
                                              context.l10n.activityDetailRemoveAction,
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) {
                                  final repo = ref.read(
                                    activityRepositoryProvider,
                                  );
                                  await repo.deleteAssignment(
                                    atama.id,
                                    actor: session!,
                                  );
                                  if (context.mounted) {
                                    AppNotifications.info(
                                      context.l10n.activityDetailPersonnelRemoved(
                                        displayName,
                                      ),
                                    );
                                  }
                                }
                            }
                          },
                          itemBuilder:
                              (ctx) => [
                                ModernMenuHeader<_AssignmentAction>(
                                  title: context.l10n.activityDetailAssignmentActions,
                                  subtitle: displayName,
                                  icon: Icons.assignment_ind_outlined,
                                ),
                                const PopupMenuDivider(),
                                ModernPopupMenuItem(
                                  option: ModernActionOption(
                                    value: _AssignmentAction.edit,
                                    title: context.l10n.commonEdit,
                                    subtitle:
                                        context.l10n.activityDetailEditDutySubtitle,
                                    icon: Icons.edit_outlined,
                                  ),
                                ),
                                ModernPopupMenuItem(
                                  option: ModernActionOption(
                                    value: _AssignmentAction.transfer,
                                    title: context.l10n.activityDetailTransferCard,
                                    subtitle:
                                        context.l10n.activityDetailTransferCardSubtitle,
                                    icon: Icons.swap_horiz_rounded,
                                  ),
                                ),
                                const PopupMenuDivider(),
                                ModernPopupMenuItem(
                                  option: ModernActionOption(
                                    value: _AssignmentAction.delete,
                                    title: context.l10n.activityDetailRemoveFromActivity,
                                    subtitle: context.l10n.activityDetailRemoveFromActivitySubtitle,
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
