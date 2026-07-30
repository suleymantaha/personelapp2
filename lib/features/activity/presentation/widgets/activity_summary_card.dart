import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_detail_sheet.dart';

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.blockedCount == 0
              ? '${result.approvedCount} atama onaylandı.'
              : '${result.approvedCount} onaylandı, '
                  '${result.blockedCount} çakışma nedeniyle beklemede kaldı: '
                  '${result.conflictDescriptions.join(', ')}',
        ),
        backgroundColor: result.blockedCount == 0
            ? context.approvedColor
            : context.pendingColor,
      ),
    );
  }

  Future<void> _deleteActivity(
    BuildContext context,
    AppDatabase db,
  ) async {
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
      )..where((tbl) => tbl.id.equals(activity.id)))
          .go();
    }
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
  }) {
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
        onSelected: (action) async {
          switch (action) {
            case _ActivityAdminAction.approveAll:
              await _approveAll(context, ref);
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
          if (hasPending)
            const PopupMenuItem(
              value: _ActivityAdminAction.approveAll,
              child: ListTile(
                leading: Icon(Icons.done_all),
                title: Text('Tümünü onayla'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          const PopupMenuItem(
            value: _ActivityAdminAction.changeDate,
            child: ListTile(
              leading: Icon(Icons.edit_calendar_outlined),
              title: Text('Tarihi değiştir'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: _ActivityAdminAction.delete,
            child: ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: context.rejectedColor,
              ),
              title: Text(
                'Faaliyeti sil',
                style: TextStyle(color: context.rejectedColor),
              ),
              contentPadding: EdgeInsets.zero,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faaliyet zaten seçilen tarihte.')),
      );
      return;
    }
    if (!preview.canChange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarih değişikliği hazırlanamadı.'),
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: context.rejectedColor,
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    if (result.status == ActivityDateChangeStatus.success) {
      onDateChanged(result.newDate);
      final pendingMessage = result.pendingAssignmentCount > 0
          ? ' ${result.pendingAssignmentCount} personel yeniden onay bekliyor.'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.assignmentCount} personel '
            '${DateFormat('dd.MM.yyyy').format(picked)} tarihine taşındı.'
            '$pendingMessage',
          ),
          backgroundColor: context.approvedColor,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Tarih değiştirilemedi. Hedef tarih yeniden kontrol edilmelidir.',
        ),
        backgroundColor: context.rejectedColor,
      ),
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
      )..where((tbl) => tbl.faaliyetId.equals(activity.id)))
          .watch(),
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
                elevation: isSelected ? 5 : 1,
                color: isSelected
                    ? context.accentOrOlive.withValues(alpha: 0.12)
                    : context.colorScheme.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected
                        ? context.accentOrOlive
                        : statusColor.withValues(alpha: 0.5),
                    width: isSelected ? 2.5 : 1.25,
                  ),
                ),
                child: IgnorePointer(
                  ignoring: selectionMode,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
                    childrenPadding: const EdgeInsets.only(bottom: 6),
                    leading: CircleAvatar(
                      backgroundColor: statusColor,
                      child: Icon(statusIcon, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      activity.faaliyetAdi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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
                                fontSize: 12,
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

enum _ActivityAdminAction { approveAll, changeDate, delete }
