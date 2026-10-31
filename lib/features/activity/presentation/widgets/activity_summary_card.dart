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
import 'package:personelapp2/features/activity/presentation/widgets/activity_detail_sheet.dart';
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

  Future<void> _deleteActivity(BuildContext context, AppDatabase db) async {
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
      await (db.delete(
        db.gunlukFaaliyetTable,
      )..where((tbl) => tbl.id.equals(activity.id)))
          .go();
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
              await _deleteActivity(context, db);
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
          onPressed: () => _deleteActivity(context, db),
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
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;
    final db = ref.watch(databaseProvider);

    return StreamBuilder<List<FaaliyetPersonelAtamaTableData>>(
      stream: (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((tbl) => tbl.faaliyetId.equals(activity.id)))
          .watch(),
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];
        if (selectedSquadId != null &&
            snapshot.hasData &&
            !assignments.any(
              (assignment) => assignment.gorevTimId == selectedSquadId,
            )) {
          return const SizedBox.shrink();
        }
        final hasPending = assignments.any(
          (a) => a.durum == AssignmentStatus.beklemede,
        );
        final hasRejected = assignments.any(
          (a) => a.durum == AssignmentStatus.reddedildi,
        );

        var statusLabel = context.l10n.activityStatusApproved;
        var statusColor = context.approvedColor;
        var statusIcon = Icons.check_circle_outline;

        if (hasPending) {
          statusLabel = context.l10n.activityStatusPendingAdmin;
          statusColor = context.pendingColor;
          statusIcon = Icons.hourglass_top;
        } else if (hasRejected) {
          statusLabel = context.l10n.activityStatusConflictOrRejected;
          statusColor = context.rejectedColor;
          statusIcon = Icons.cancel_outlined;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            return AppCard(
              key: Key('activity-card-${activity.id}'),
              elevation: isSelected ? 3 : 1.5,
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.only(bottom: 10),
              borderRadius: BorderRadius.circular(18),
              backgroundColor: isSelected
                  ? context.accentOrOlive.withValues(alpha: 0.12)
                  : context.colorScheme.surface,
              borderColor: isSelected
                  ? context.accentOrOlive
                  : (hasPending || hasRejected
                      ? statusColor.withValues(alpha: 0.38)
                      : context.cardBorderColor),
              onLongPress: onLongPress,
              onTap: selectionMode ? onSelectionToggle : null,
              child: IgnorePointer(
                ignoring: selectionMode,
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.fromLTRB(12, 2, 6, 2),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: statusColor,
                    child: Icon(statusIcon, color: Colors.white, size: 23),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.faaliyetAdi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 16 : 17,
                          ),
                        ),
                      ),
                      if (isAdmin && !selectionMode)
                        _buildAdminActions(
                          context,
                          ref,
                          db,
                          assignments,
                          hasPending: hasPending,
                          compact: true,
                        ),
                    ],
                  ),
                  subtitle: hasPending || hasRejected
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _buildStatusBadge(
                              label: statusLabel,
                              color: statusColor,
                            ),
                          ),
                        )
                      : null,
                  trailing: selectionMode
                      ? Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? context.accentOrOlive
                              : context.textSecondary,
                        )
                      : null,
                  children: [
                    ActivityAssignmentDetails(
                      activity: activity,
                      assignments: assignments,
                      selectedSquadId: selectedSquadId,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

enum _ActivityAdminAction { approveAll, rename, changeDate, copy, delete }
