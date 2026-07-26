import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_detail_sheet.dart';

class ActivityCard extends ConsumerWidget {
  const ActivityCard({
    required this.activity,
    this.selectedSquadId,
    super.key,
  });

  final GunlukFaaliyetTableData activity;
  final int? selectedSquadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? true;
    final db = ref.watch(databaseProvider);

    return StreamBuilder<List<FaaliyetPersonelAtamaTableData>>(
      stream: (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((tbl) => tbl.faaliyetId.equals(activity.id))).watch(),
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];
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

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: statusColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: Icon(statusIcon, color: Colors.white, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    activity.faaliyetAdi,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${activity.tarih} • Yazan: ${activity.olusturanKullanici}',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
            trailing: isAdmin
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasPending)
                        IconButton(
                          icon: Icon(
                            Icons.done_all,
                            color: context.approvedColor,
                          ),
                          tooltip: 'Tümünü Onayla',
                          onPressed: () async {
                            final repo = ref.read(activityRepositoryProvider);
                            await repo.approveAllAssignmentsForActivity(
                              activity.id,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Faaliyet atamaları onaylandı!',
                                  ),
                                  backgroundColor: context.approvedColor,
                                ),
                              );
                            }
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: context.rejectedColor,
                        ),
                        tooltip: 'Faaliyeti Sil',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Faaliyeti Sil'),
                              content: Text(
                                '${activity.faaliyetAdi} (${activity.tarih}) faaliyet kaydı silinecektir. Emin misiniz?',
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
                        },
                      ),
                    ],
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
        );
      },
    );
  }
}
