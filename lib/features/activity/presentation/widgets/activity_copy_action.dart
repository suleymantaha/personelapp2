import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/task_team_confirmation.dart';

Future<void> copyActivityFromCard({
  required BuildContext context,
  required WidgetRef ref,
  required GunlukFaaliyetTableData activity,
  required ValueChanged<String> onDateChanged,
}) async {
  final actor = ref.read(userSessionProvider);
  if (actor == null || !actor.isAdmin) return;
  final repository = ref.read(activityRepositoryProvider);
  try {
    final assignments = await (repository.db.select(
      repository.db.faaliyetPersonelAtamaTable,
    )..where((a) => a.faaliyetId.equals(activity.id)))
        .get();
    if (!context.mounted) return;
    if (assignments.isEmpty) {
      AppNotifications.info('Kartta kopyalanacak personel yok.');
      return;
    }
    final picked = await showDatePicker(
      context: context,
      helpText: 'Başka Güne Kopyala',
      initialDate: DateTime.tryParse(activity.tarih) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !context.mounted) return;
    final date = DateFormat('yyyy-MM-dd').format(picked);
    if (date == activity.tarih) {
      AppNotifications.info('Kopyalamak için başka bir gün seçin.');
      return;
    }
    final choices = await confirmTaskTeams(
      context: context,
      repository: repository,
      date: date,
      assignments: [
        for (final row in assignments)
          PersonnelAssignmentInput(
            personnelId: row.personelId,
            duty: row.gorevVeyaIzin,
            note: row.aciklama,
          ),
      ],
      actor: actor,
    );
    if (choices == null || !context.mounted) return;
    final result = await repository.copyActivityToDate(
      activityId: activity.id,
      newDate: date,
      actor: actor,
      expectedDate: activity.tarih,
      expectedAssignments: assignments,
      teamConfirmations: choices,
    );
    if (!context.mounted) return;
    if (result.addedCount > 0) onDateChanged(date);
    final summary = '${result.addedCount} personel kopyalandı. '
        '${result.alreadyAssignedCount} personel zaten kayıtlı. '
        '${result.conflictSkippedCount} personel çakışma nedeniyle eklenmedi.';
    if (result.conflictSkippedCount > 0) {
      AppNotifications.warning([
        summary,
        ...result.conflictDescriptions,
      ].join('\n'));
    } else if (result.addedCount > 0) {
      AppNotifications.success(summary);
    } else {
      AppNotifications.info(summary);
    }
  } on AssignmentConflictException catch (error) {
    if (context.mounted) {
      AppNotifications.error(error.localizedMessage(context.l10n));
    }
  } on StateError catch (_) {
    if (context.mounted) {
      AppNotifications.error('Kart değişti; güncel kartı açıp tekrar deneyin.');
    }
  } on Object catch (_) {
    if (context.mounted) {
      AppNotifications.error('Kart kopyalanamadı. Tekrar deneyin.');
    }
  }
}
