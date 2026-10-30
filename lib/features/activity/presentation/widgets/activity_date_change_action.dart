import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/task_team_confirmation.dart';

Future<void> changeActivityDateFromCard({
  required BuildContext context,
  required WidgetRef ref,
  required GunlukFaaliyetTableData activity,
  required ValueChanged<String> onDateChanged,
}) async {
  final actor = ref.read(userSessionProvider);
  if (actor == null || !actor.isAdmin) return;
  final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(activity.tarih) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100));
  if (picked == null || !context.mounted) return;
  final newDate = DateFormat('yyyy-MM-dd').format(picked);
  final repository = ref.read(activityRepositoryProvider);
  try {
    final preview = await repository.previewActivityDateChange(
        activityId: activity.id, newDate: newDate, actor: actor);
    if (!context.mounted) return;
    if (preview.status == ActivityDateChangeStatus.unchanged) {
      AppNotifications.info(context.l10n.activityChangeDateAlreadyOnDate);
      return;
    }
    if (!preview.canChange) {
      AppNotifications.error(context.l10n.activityChangeDatePrepareFailed);
      return;
    }
    if (!await _confirmDateChange(context, preview) || !context.mounted) return;
    var confirmations = <PersonnelAssignmentInput>[];
    if (preview.teamConfirmationPersonnelIds.isNotEmpty) {
      final assignments =
          await (repository.db.select(repository.db.faaliyetPersonelAtamaTable)
                ..where((a) => a.faaliyetId.equals(activity.id)))
              .get();
      if (!context.mounted) return;
      final requiredIds = preview.teamConfirmationPersonnelIds;
      final choices = await confirmTaskTeams(
          context: context,
          repository: repository,
          date: newDate,
          assignments: [
            for (final assignment in assignments)
              if (requiredIds.contains(assignment.personelId))
                PersonnelAssignmentInput(
                    personnelId: assignment.personelId,
                    duty: assignment.gorevVeyaIzin,
                    note: assignment.aciklama)
          ],
          actor: actor,
          forceConfirmationFor: requiredIds);
      if (choices == null || !context.mounted) return;
      confirmations = choices;
    }
    final result = await repository.changeActivityDate(
        activityId: activity.id,
        newDate: newDate,
        actor: actor,
        expectedDate: preview.oldDate,
        expectedAssignments: preview.assignmentSnapshot,
        teamConfirmations: confirmations);
    if (!context.mounted) return;
    if (result.status == ActivityDateChangeStatus.success) {
      onDateChanged(result.newDate);
      AppNotifications.success(context.l10n.activityChangeDateMovedNotice(
          result.assignmentCount, DateFormat('dd.MM.yyyy').format(picked)));
    } else {
      AppNotifications.error(context.l10n.activityChangeDateFailed);
    }
  } on AssignmentConflictException catch (error) {
    if (context.mounted) {
      AppNotifications.error(error.localizedMessage(context.l10n));
    }
  } on TaskTeamRequiredException {
    if (context.mounted) {
      AppNotifications.error(
          'Görev timi bilgisi değişti. İşlemi yeniden deneyin.');
    }
  } on StateError {
    if (context.mounted) {
      AppNotifications.error('Kayıt değişti. İşlemi yeniden deneyin.');
    }
  } catch (_) {
    if (context.mounted) {
      AppNotifications.error(context.l10n.activityChangeDateFailed);
    }
  }
}

Future<bool> _confirmDateChange(
    BuildContext context, ActivityDateChangePreview preview) async {
  String displayDate(String value) =>
      DateFormat('dd.MM.yyyy').format(DateTime.parse(value));
  return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                  title: Text(dialogContext.l10n.activityChangeDateTitle),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${displayDate(preview.oldDate)} → '
                        '${displayDate(preview.newDate)}'),
                    const SizedBox(height: 12),
                    Text(dialogContext.l10n
                        .activityChangeDatePersonnelCountNotice(
                            preview.assignmentCount)),
                    if (preview.pendingAssignmentCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(dialogContext.l10n.activityChangeDatePendingNotice(
                          preview.pendingAssignmentCount)),
                    ],
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(dialogContext.l10n.commonCancel)),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child:
                            Text(dialogContext.l10n.activityChangeDateSubmit)),
                  ])) ??
      false;
}
