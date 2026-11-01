import 'package:personelapp2/features/activity/presentation/activity_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/widgets/app_card.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_date_change_action.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_copy_action.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';

class ActivityCard extends ConsumerWidget {
  const ActivityCard({
    required this.activity,
    required this.onDateChanged,
    this.selectedSquadId,
    this.selectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelectionToggle,
    super.key,
  });

  final GunlukFaaliyetTableData activity;
  final ValueChanged<String> onDateChanged;
  final int? selectedSquadId;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;

  Future<void> _approveAll(BuildContext context, WidgetRef ref) async {
    final session = ref.read(userSessionProvider);
    if (session == null) return;

    final repo = ref.read(activityRepositoryProvider);
    final result = await repo.approveAllAssignmentsForActivity(
      activity.id,
      actor: session,
    );
    if (!context.mounted) return;

    final message = result.blockedCount == 0
        ? context.l10n.activityApproveAllSuccess(result.approvedCount)
        : context.l10n.activityApproveAllWithConflicts(
            result.approvedCount,
            result.blockedCount,
            result.conflictDescriptions.join(', '),
          );
    if (result.blockedCount == 0) {
      AppNotifications.success(message);
    } else {
      AppNotifications.warning(message);
    }
  }

  Future<void> _deleteActivity(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.activityDeleteTitle),
        content: Text(
          ctx.l10n.activityDeleteConfirm(activity.faaliyetAdi, activity.tarih),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.rejectedColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final actor = ref.read(userSessionProvider);
      if (actor == null) return;
      try {
        await ref
            .read(activityRepositoryProvider)
            .deleteActivity(activityId: activity.id, actor: actor);
      } catch (error) {
        if (context.mounted) AppNotifications.error('$error');
      }
    }
  }

  Widget _buildStatusBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAdminActions(
    BuildContext context,
    WidgetRef ref,
    AppDatabase db,
    List<FaaliyetPersonelAtamaTableData> assignments, {
    required bool hasPending,
    required bool compact,
  }) {
    if (compact) {
      return PopupMenuButton<_ActivityAdminAction>(
        key: Key('activity-actions-${activity.id}'),
        tooltip: context.l10n.activityActionsTitle,
        icon: const Icon(Icons.more_vert_rounded),
        elevation: 5,
        shadowColor: context.shadowColor,
        surfaceTintColor: context.colorScheme.surface,
        shape: modernPopupShape(context),
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
        onSelected: (action) async {
          switch (action) {
            case _ActivityAdminAction.approveAll:
              await _approveAll(context, ref);
              return;
            case _ActivityAdminAction.rename:
              await _renameActivity(context, ref);
              return;
            case _ActivityAdminAction.changeDate:
              await changeActivityDateFromCard(
                  context: context,
                  ref: ref,
                  activity: activity,
                  onDateChanged: onDateChanged);
              return;
            case _ActivityAdminAction.copy:
              await copyActivityFromCard(
                context: context,
                ref: ref,
                activity: activity,
                onDateChanged: onDateChanged,
              );
              return;
            case _ActivityAdminAction.delete:
              await _deleteActivity(context, ref);
              return;
          }
        },
        itemBuilder: (context) => [
          ModernMenuHeader<_ActivityAdminAction>(
            title: context.l10n.activityActionsTitle,
            subtitle: context.l10n.activityActionsSubtitle,
            icon: Icons.event_note_outlined,
          ),
          const PopupMenuDivider(),
          if (hasPending)
            ModernPopupMenuItem(
              option: ModernActionOption(
                value: _ActivityAdminAction.approveAll,
                title: context.l10n.activityApproveAllTitle,
                subtitle: context.l10n.activityApproveAllSubtitle,
                icon: Icons.done_all_rounded,
              ),
            ),
          ModernPopupMenuItem(
            option: ModernActionOption(
              value: _ActivityAdminAction.rename,
              title: context.l10n.activityRenameOptionTitle,
              subtitle: context.l10n.activityRenameOptionSubtitle,
              icon: Icons.drive_file_rename_outline_rounded,
            ),
          ),
          ModernPopupMenuItem(
            option: ModernActionOption(
              value: _ActivityAdminAction.changeDate,
              title: context.l10n.activityChangeDateOptionTitle,
              subtitle: context.l10n.activityChangeDateOptionSubtitle,
              icon: Icons.edit_calendar_outlined,
            ),
          ),
          ModernPopupMenuItem(
            option: ModernActionOption(
              value: _ActivityAdminAction.copy,
              title: 'Başka Güne Kopyala',
              subtitle: 'Aynı personelleri ve görevleri seçilen güne ekle',
              icon: Icons.copy_outlined,
            ),
          ),
          const PopupMenuDivider(),
          ModernPopupMenuItem(
            option: ModernActionOption(
              value: _ActivityAdminAction.delete,
              title: context.l10n.activityDeleteOptionTitle,
              subtitle: context.l10n.activityDeleteOptionSubtitle,
              icon: Icons.delete_outline_rounded,
              isDestructive: true,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPending)
          IconButton(
            icon: Icon(Icons.done_all, color: context.approvedColor),
            tooltip: context.l10n.activityApproveAllTitle,
            onPressed: () => _approveAll(context, ref),
          ),
        IconButton(
          icon: Icon(
            Icons.drive_file_rename_outline_rounded,
            color: context.accentOrOlive,
          ),
          tooltip: context.l10n.activityRenameOptionTitle,
          onPressed: () => _renameActivity(context, ref),
        ),
        IconButton(
          icon: Icon(
            Icons.edit_calendar_outlined,
            color: context.accentOrOlive,
          ),
          tooltip: context.l10n.activityChangeDateOptionTitle,
          onPressed: () => changeActivityDateFromCard(
              context: context,
              ref: ref,
              activity: activity,
              onDateChanged: onDateChanged),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: context.rejectedColor),
          tooltip: context.l10n.activityDeleteOptionTitle,
          onPressed: () => _deleteActivity(context, ref),
        ),
      ],
    );
  }

  Future<void> _renameActivity(BuildContext context, WidgetRef ref) async {
    var editedName = activity.faaliyetAdi;
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.activityRenameTitle),
        content: TextFormField(
          key: const Key('activity-name-field'),
          initialValue: activity.faaliyetAdi,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 100,
          decoration: InputDecoration(
            labelText: dialogContext.l10n.activityRenameLabel,
            hintText: dialogContext.l10n.activityRenameHint,
            prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
          ),
          onChanged: (value) => editedName = value,
          onFieldSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.of(dialogContext).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final value = editedName.trim();
              if (value.isNotEmpty) Navigator.of(dialogContext).pop(value);
            },
            child: Text(dialogContext.l10n.commonSave),
          ),
        ],
      ),
    );
    if (newName == null || !context.mounted) return;
    final l10n = context.l10n;

    final session = ref.read(userSessionProvider);
    if (session == null) return;
    try {
      await ref.read(activityRepositoryProvider).renameActivity(
            activityId: activity.id,
            newName: newName,
            actor: session,
          );
      AppNotifications.success(l10n.activityRenameSuccess);
    } on Object catch (error) {
      AppNotifications.error(l10n.activityRenameFailed('$error'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final session = ref.watch(userSessionProvider);
    final authority = ref.watch(commanderAuthorityProvider).valueOrNull;
    return StreamBuilder<List<FaaliyetPersonelAtamaTableData>>(
      stream: (db.select(db.faaliyetPersonelAtamaTable)
            ..where((t) => t.faaliyetId.equals(activity.id)))
          .watch(),
      builder: (context, snapshot) {
        final rows = (snapshot.data ?? [])
            .where((row) =>
                (session?.isAdmin == true ||
                    authority != null && row.gorevTimId == authority) &&
                (selectedSquadId == null || row.gorevTimId == selectedSquadId))
            .toList();
        if (selectedSquadId != null && snapshot.hasData && rows.isEmpty) {
          return const SizedBox.shrink();
        }
        final pending =
            rows.where((r) => r.durum == AssignmentStatus.beklemede).length;
        final rejected =
            rows.where((r) => r.durum == AssignmentStatus.reddedildi).length;
        final color =
            pending > 0 ? context.pendingColor : context.accentOrOlive;
        return AppCard(
          key: Key('activity-card-${activity.id}'),
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.only(bottom: 6),
          borderRadius: BorderRadius.circular(14),
          borderColor:
              isSelected ? context.accentOrOlive : context.cardBorderColor,
          onLongPress: onLongPress,
          onTap: selectionMode
              ? onSelectionToggle
              : () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                        builder: (_) => ActivityDetailScreen(
                              activityId: activity.id,
                              selectedSquadId: selectedSquadId,
                              actionsBuilder: (ctx, r, current, assignments) =>
                                  ActivityCard(
                                activity: current,
                                onDateChanged: onDateChanged,
                              )._buildAdminActions(ctx, r, db, assignments,
                                      hasPending: assignments.any((a) =>
                                          a.durum ==
                                          AssignmentStatus.beklemede),
                                      compact: true),
                            )),
                  ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(
                  selectionMode
                      ? isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank
                      : pending > 0
                          ? Icons.schedule
                          : Icons.fact_check_outlined,
                  color: color,
                  size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.faaliyetAdi,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text('${rows.map((r) => r.gorevTimId).toSet().length} tim · '
                      '${rows.map((r) => r.personelId).toSet().length} personel'),
                  if (pending > 0 || rejected > 0) ...[
                    const SizedBox(height: 4),
                    Wrap(spacing: 8, children: [
                      if (pending > 0)
                        _buildStatusBadge(
                            label: '$pending bekleyen',
                            color: context.pendingColor),
                      if (rejected > 0)
                        _buildStatusBadge(
                            label: '$rejected reddedilen',
                            color: context.rejectedColor),
                    ]),
                  ],
                ],
              )),
              if (!selectionMode && session?.isAdmin == true)
                _buildAdminActions(context, ref, db, rows,
                    hasPending: pending > 0, compact: true),
              if (!selectionMode) const Icon(Icons.chevron_right),
            ]),
          ),
        );
      },
    );
  }
}

enum _ActivityAdminAction { approveAll, rename, changeDate, copy, delete }
