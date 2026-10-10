import 'package:flutter/material.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/widgets/app_card.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

class PendingApprovalsScreen extends ConsumerWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    if (session?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(context.l10n.pendingApprovalsTitle),
        ),
        body: Center(
          child: Text(context.l10n.commonUnauthorized),
        ),
      );
    }

    final pendingAsync = ref.watch(pendingAssignmentsProvider);
    final personnelAsync = ref.watch(allPersonnelProvider);

    final personnelList = personnelAsync.value ?? [];
    final pMap = {for (final p in personnelList) p.id: p};

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(context.l10n.pendingApprovalsTitle),
      ),
      body: TurkishFlagWatermarkBackground(
        child: pendingAsync.when(
          data: (pendingList) {
            if (pendingList.isEmpty) {
              return AppEmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: context.l10n.pendingApprovalsEmptyTitle,
                description: context.l10n.pendingApprovalsEmptyDesc,
              );
            }

            return ResponsiveCenter(
              maxWidth: AppSpacing.readableContentWidth,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                itemCount: pendingList.length,
                itemBuilder: (context, index) {
                  final atama = pendingList[index];
                  final p = pMap[atama.personelId];
                  final nameText = p?.adSoyad ?? 'Personel #${atama.personelId}';
                  final rutbeText = p?.rutbe ?? '';
                  final birlikInfo = p?.birlik ?? '';
                  final fullPersonName =
                      rutbeText.isNotEmpty ? '$rutbeText $nameText' : nameText;
                  final squadInfo = birlikInfo.isNotEmpty ? ' ($birlikInfo)' : '';

                  return AppCard(
                    elevation: 1,
                    borderColor: context.pendingColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: context.pendingColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.pendingApprovalsAssignmentConflict(atama.id),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: '${context.l10n.pendingApprovalsPersonnelLabel}: ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: '$fullPersonName$squadInfo',
                                style: TextStyle(
                                  color: context.accentOrOlive,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: '${context.l10n.pendingApprovalsRequestedDutyLabel}: ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: atama.gorevVeyaIzin,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (atama.aciklama != null &&
                            atama.aciklama!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.pendingApprovalsDescriptionLabel(atama.aciklama!),
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        OverflowBar(
                          alignment: MainAxisAlignment.end,
                          spacing: AppSpacing.sm,
                          overflowSpacing: AppSpacing.sm,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.rejectedColor,
                              ),
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
                              child: Text(context.l10n.pendingApprovalsReject),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.approvedColor,
                                foregroundColor: context.onStatusColor(context.approvedColor),
                              ),
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
                                    context.l10n.pendingApprovalsApprovalFailed(
                                      result.conflictDescriptions.join(', '),
                                    ),
                                  );
                                }
                              },
                              child: Text(context.l10n.pendingApprovalsApprove),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => AppErrorState(
            title: context.l10n.commonError,
            error: '$err',
          ),
        ),
      ),
    );
  }
}
