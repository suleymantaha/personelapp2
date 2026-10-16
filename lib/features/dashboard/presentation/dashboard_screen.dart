import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';
import 'package:personelapp2/features/activity/services/roster_image_import_service.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/features/dashboard/presentation/models/dashboard_action_item.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_action_tone.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_grid_layout.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_menu_card.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_settings.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;
    final pendingAsync = ref.watch(pendingAssignmentsProvider);

    // Left-to-right, low-to-high usage: the frequently used screens sit last.
    // On the administrator dashboard, 2 columns x 4 rows.
    final gridActions = <DashboardActionItem>[
      DashboardActionItem(
        icon: Icons.people_alt,
        title: context.l10n.dashboardPersonnelAndSquad,
        subtitle: isAdmin
            ? context.l10n.dashboardRegisterAndAuth
            : context.l10n.dashboardRosterStatus,
        tone: DashboardActionTone.personnel,
        onTap: () => AppNavigator.toPersonnelManagement(context),
      ),
      DashboardActionItem(
        icon: Icons.insights_outlined,
        title: 'Tim Görev Analizi',
        subtitle: 'Katılım, görev günleri ve karşılaştırmalar',
        tone: DashboardActionTone.neutral,
        onTap: () => AppNavigator.toTeamAnalytics(context),
      ),
      DashboardActionItem(
        icon: Icons.grid_on,
        title: context.l10n.dashboardMonthlyMatrix,
        subtitle: context.l10n.dashboardExcelDistribution,
        tone: DashboardActionTone.neutral,
        onTap: () => AppNavigator.toMonthlyMatrix(context),
      ),
      if (isAdmin) DashboardActionItem(
          icon: Icons.image_search_rounded,
          title: context.l10n.dashboardBulkImportImage,
          subtitle: context.l10n.dashboardOcrNameMatch,
          tone: DashboardActionTone.pending,
          onTap: () async {
            final l10n = context.l10n;
            final service = RosterImageImportService();
            if (!service.isSupportedPlatform) {
              AppNotifications.warning(
                l10n.dashboardOcrPlatformWarning,
              );
              return;
            }
            try {
              final result = await service.pickAndExtract();
              if (result == null || !context.mounted) return;

              final db = ref.read(databaseProvider);
              final activityRepo = ref.read(activityRepositoryProvider);
              await showDialog<bool>(
                context: context,
                builder: (ctx) => BulkImportDialog(
                  database: db,
                  activityRepository: activityRepo,
                  initialText: result.bulkImportText,
                  isImageImport: true,
                ),
              );
              ref.invalidate(activityRepositoryProvider);
            } on RosterImageImportUnsupportedException catch (e) {
              AppNotifications.warning(e.toString());
            } on RosterImageImportNoNamesException catch (e) {
              AppNotifications.warning(e.toString());
            } on Object catch (e) {
              AppNotifications.error(
                l10n.dashboardImageReadError(e.toString()),
              );
            }
          },
        ),
      DashboardActionItem(
        icon: Icons.table_chart_outlined,
        title: 'TEMGÜNDRAP',
        subtitle: context.l10n.dashboardTemgundrapSubtitle,
        tone: DashboardActionTone.neutral,
        onTap: () => AppNavigator.toTemgundrap(context),
      ),
      if (isAdmin) DashboardActionItem(
          icon: Icons.paste_rounded,
          title: context.l10n.dashboardBulkImportText,
          subtitle: context.l10n.dashboardWhatsAppListUpload,
          tone: DashboardActionTone.import,
          onTap: () async {
            final db = ref.read(databaseProvider);
            final activityRepo = ref.read(activityRepositoryProvider);
            await showDialog<bool>(
              context: context,
              builder: (ctx) => BulkImportDialog(
                database: db,
                activityRepository: activityRepo,
              ),
            );
            ref.invalidate(activityRepositoryProvider);
          },
        ),
      DashboardActionItem(
        icon: Icons.edit_calendar,
        title: context.l10n.dashboardActivitySchedule,
        subtitle: context.l10n.dashboardDailyDutyEntry,
        tone: DashboardActionTone.primary,
        onTap: () => AppNavigator.toActivityForm(context),
      ),
      DashboardActionItem(
        icon: Icons.inventory_2_outlined,
        title: context.l10n.activityArchive,
        subtitle: context.l10n.dashboardSearchAndReview,
        tone: DashboardActionTone.neutral,
        onTap: () => AppNavigator.toActivityArchive(context),
      )
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nizam'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: context.l10n.settingsTitle,
            onPressed: () => DashboardSettings.showSettingsBottomSheet(
              context,
              ref,
              session?.username ?? context.l10n.commonUser,
              isAdmin,
            ),
          ),
        ],
      ),
      body: TurkishFlagWatermarkBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pendingList = pendingAsync.asData?.value ?? [];
            final hasWarning = isAdmin && pendingList.isNotEmpty;
            final layout = DashboardGridLayout.calculate(
              constraints,
              itemCount: gridActions.length,
              hasWarningBanner: hasWarning,
            );

            return ResponsiveCenter(
              padding: layout.padding,
              child: Column(
                children: [
                  if (hasWarning)
                    SizedBox(
                      height: constraints.maxHeight < 560 ? 52 : 72,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: layout.gap),
                        child: Material(
                          color: context.rejectedBgColor,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () =>
                                AppNavigator.toPendingApprovals(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: context.rejectedColor, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.l10n.dashboardPendingConflictsNotice(
                                          pendingList.length),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: context.rejectedColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: context.rejectedColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: GridView.builder(
                      key: const ValueKey('dashboard-action-grid'),
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: layout.columnCount,
                        mainAxisExtent: layout.mainAxisExtent,
                        crossAxisSpacing: layout.gap,
                        mainAxisSpacing: layout.gap,
                      ),
                      itemCount: gridActions.length,
                      itemBuilder: (context, index) {
                        final action = gridActions[index];
                        return DashboardMenuCard(
                          key: ValueKey('dashboard-action-${action.title}'),
                          icon: action.icon,
                          title: action.title,
                          subtitle: action.subtitle,
                          tone: action.tone,
                          animationIndex: index,
                          onTap: action.onTap,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

@Preview(name: 'TEMGÜNDRAP Dashboard Kartı', group: 'Dashboard')
Widget temgundrapDashboardCardPreview() {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 180,
          height: 184,
          child: DashboardMenuCard(
            icon: Icons.table_chart_outlined,
            title: 'TEMGÜNDRAP',
            subtitle: 'Çizelge oluştur ve yönet',
            tone: DashboardActionTone.neutral,
            onTap: _previewNoop,
          ),
        ),
      ),
    ),
  );
}

void _previewNoop() {}
