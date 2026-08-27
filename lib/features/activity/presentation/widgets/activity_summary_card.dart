import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_detail_sheet.dart';
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
        ? '${result.approvedCount} atama onaylandı.'
        : '${result.approvedCount} onaylandı, '
              '${result.blockedCount} çakışma nedeniyle beklemede kaldı: '
              '${result.conflictDescriptions.join(', ')}';
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
        title: const Text('Faaliyeti Sil'),
        content: Text(
          '${activity.faaliyetAdi} (${activity.tarih}) faaliyet kaydı '
          'silinecektir. Emin misiniz?',
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
            child: const Text('SİL'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await (db.delete(
        db.gunlukFaaliyetTable,
      )..where((tbl) => tbl.id.equals(activity.id))).go();
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
        tooltip: 'Faaliyet işlemleri',
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
              await _changeDate(context, ref, assignments.length);
              return;
            case _ActivityAdminAction.delete:
              await _deleteActivity(context, db);
              return;
          }
        },
        itemBuilder: (context) => [
          const ModernMenuHeader<_ActivityAdminAction>(
            title: 'Faaliyet İşlemleri',
            subtitle: 'Bu faaliyet için kullanılabilir işlemler',
            icon: Icons.event_note_outlined,
          ),
          const PopupMenuDivider(),
          if (hasPending)
            ModernPopupMenuItem(
              option: const ModernActionOption(
                value: _ActivityAdminAction.approveAll,
                title: 'Tümünü onayla',
                subtitle: 'Bekleyen tüm atamaları onayla',
                icon: Icons.done_all_rounded,
              ),
            ),
          ModernPopupMenuItem(
            option: const ModernActionOption(
              value: _ActivityAdminAction.rename,
              title: 'Faaliyet adını değiştir',
              subtitle: 'Kart başlığını yeniden adlandır',
              icon: Icons.drive_file_rename_outline_rounded,
            ),
          ),
          ModernPopupMenuItem(
            option: const ModernActionOption(
              value: _ActivityAdminAction.changeDate,
              title: 'Tarihi değiştir',
              subtitle: 'Faaliyeti başka bir güne taşı',
              icon: Icons.edit_calendar_outlined,
            ),
          ),
          const PopupMenuDivider(),
          ModernPopupMenuItem(
            option: const ModernActionOption(
              value: _ActivityAdminAction.delete,
              title: 'Faaliyeti sil',
              subtitle: 'Bu işlem geri alınamaz',
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
            tooltip: 'Tümünü Onayla',
            onPressed: () => _approveAll(context, ref),
          ),
        IconButton(
          icon: Icon(
            Icons.drive_file_rename_outline_rounded,
            color: context.accentOrOlive,
          ),
          tooltip: 'Faaliyet Adını Değiştir',
          onPressed: () => _renameActivity(context, ref),
        ),
        IconButton(
          icon: Icon(
            Icons.edit_calendar_outlined,
            color: context.accentOrOlive,
          ),
          tooltip: 'Faaliyet Tarihini Değiştir',
          onPressed: () => _changeDate(context, ref, assignments.length),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: context.rejectedColor),
          tooltip: 'Faaliyeti Sil',
          onPressed: () => _deleteActivity(context, db),
        ),
      ],
    );
  }

  Future<void> _renameActivity(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: activity.faaliyetAdi);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Faaliyet Adını Değiştir'),
        content: TextField(
          key: const Key('activity-name-field'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'Faaliyet adı',
            hintText: 'Örn. Gece nöbeti',
            prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.of(dialogContext).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.of(dialogContext).pop(value);
            },
            child: const Text('KAYDET'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || !context.mounted) return;

    final session = ref.read(userSessionProvider);
    if (session == null) return;
    try {
      await ref
          .read(activityRepositoryProvider)
          .renameActivity(
            activityId: activity.id,
            newName: newName,
            actor: session,
          );
      AppNotifications.success('Faaliyet adı güncellendi.');
    } on Object catch (error) {
      AppNotifications.error('Faaliyet adı değiştirilemedi: $error');
    }
  }

  Future<void> _changeDate(
    BuildContext context,
    WidgetRef ref,
    int assignmentCount,
  ) async {
    final currentDate = DateTime.tryParse(activity.tarih) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !context.mounted) return;
    final newDate = DateFormat('yyyy-MM-dd').format(picked);
    final repository = ref.read(activityRepositoryProvider);
    final preview = await repository.previewActivityDateChange(
      activityId: activity.id,
      newDate: newDate,
    );
    if (!context.mounted) return;

    if (preview.status == ActivityDateChangeStatus.unchanged) {
      AppNotifications.info('Faaliyet zaten seçilen tarihte.');
      return;
    }
    if (!preview.canChange) {
      AppNotifications.error('Tarih değişikliği hazırlanamadı.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Faaliyet Tarihini Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('dd.MM.yyyy').format(currentDate)} → '
              '${DateFormat('dd.MM.yyyy').format(picked)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('$assignmentCount personel yeni tarihe taşınacak.'),
            if (preview.pendingAssignmentCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${preview.pendingAssignmentCount} personel rapor/görev '
                'çakışması nedeniyle yeniden onaya alınacak.',
                style: TextStyle(color: context.pendingColor),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('TARİHİ DEĞİŞTİR'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    ActivityDateChangeResult result;
    try {
      result = await repository.changeActivityDate(
        activityId: activity.id,
        newDate: newDate,
      );
    } on AssignmentConflictException catch (error) {
      if (context.mounted) {
        AppNotifications.error(error.message);
      }
      return;
    }
    if (!context.mounted) return;
    if (result.status == ActivityDateChangeStatus.success) {
      onDateChanged(result.newDate);
      final pendingMessage = result.pendingAssignmentCount > 0
          ? ' ${result.pendingAssignmentCount} personel yeniden onay bekliyor.'
          : '';
      AppNotifications.success(
        '${result.assignmentCount} personel '
        '${DateFormat('dd.MM.yyyy').format(picked)} tarihine taşındı.'
        '$pendingMessage',
      );
      return;
    }
    AppNotifications.error(
      'Tarih değiştirilemedi. Hedef tarih yeniden kontrol edilmelidir.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;
    final db = ref.watch(databaseProvider);

    return StreamBuilder<List<FaaliyetPersonelAtamaTableData>>(
      stream: (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((tbl) => tbl.faaliyetId.equals(activity.id))).watch(),
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];
        final personnel = ref.watch(allPersonnelProvider).value ?? [];
        if (selectedSquadId != null &&
            snapshot.hasData &&
            !assignments.any(
              (assignment) => personnel.any(
                (person) =>
                    person.id == assignment.personelId &&
                    person.timId == selectedSquadId,
              ),
            )) {
          return const SizedBox.shrink();
        }
        final hasPending = assignments.any(
          (a) => a.durum == AssignmentStatus.beklemede,
        );
        final hasRejected = assignments.any(
          (a) => a.durum == AssignmentStatus.reddedildi,
        );

        var statusLabel = 'ONAYLANDI';
        var statusColor = context.approvedColor;
        var statusIcon = Icons.check_circle_outline;

        if (hasPending) {
          statusLabel = 'ADMIN ONAYI BEKLİYOR';
          statusColor = context.pendingColor;
          statusIcon = Icons.hourglass_top;
        } else if (hasRejected) {
          statusLabel = 'ÇAKIŞMA / RED';
          statusColor = context.rejectedColor;
          statusIcon = Icons.cancel_outlined;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            return GestureDetector(
              key: Key('activity-card-${activity.id}'),
              behavior: HitTestBehavior.opaque,
              onLongPress: onLongPress,
              onTap: selectionMode ? onSelectionToggle : null,
              child: Card(
                elevation: isSelected ? 5 : 2,
                color: isSelected
                    ? context.accentOrOlive.withValues(alpha: 0.12)
                    : context.colorScheme.surface,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isSelected
                        ? context.accentOrOlive
                        : statusColor.withValues(alpha: 0.5),
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: IgnorePointer(
                  ignoring: selectionMode,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: statusColor,
                      child: Icon(statusIcon, color: Colors.white, size: 25),
                    ),
                    title: Text(
                      activity.faaliyetAdi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 16 : 17,
                        letterSpacing: 0.15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Flexible(
                            child: _buildStatusBadge(
                              label: statusLabel,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Yazan: ${activity.olusturanKullanici}',
                              maxLines: compact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                          if (isAdmin)
                            _buildAdminActions(
                              context,
                              ref,
                              db,
                              assignments,
                              hasPending: hasPending,
                              compact: compact,
                            ),
                        ],
                      ),
                    ),
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
              ),
            );
          },
        );
      },
    );
  }
}

enum _ActivityAdminAction { approveAll, rename, changeDate, delete }
