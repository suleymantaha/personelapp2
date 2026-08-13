import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';
import 'package:personelapp2/features/activity/services/roster_image_import_service.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/features/dashboard/presentation/models/dashboard_action_item.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_action_tone.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_archive_action.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_grid_layout.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_menu_card.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_settings.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;
    final pendingAsync = ref.watch(pendingAssignmentsProvider);

    final gridActions = <DashboardActionItem>[
      DashboardActionItem(
        icon: Icons.edit_calendar,
        title: 'Faaliyet Çizelgesi',
        subtitle: 'Günlük görev gir',
        tone: DashboardActionTone.primary,
        onTap: () => context.push('/activity-form'),
      ),
      DashboardActionItem(
        icon: Icons.grid_on,
        title: 'Aylık Matris',
        subtitle: 'Excel / Dağıtım',
        tone: DashboardActionTone.neutral,
        onTap: () => context.push('/monthly-matrix'),
      ),
      DashboardActionItem(
        icon: Icons.table_chart_outlined,
        title: 'TEMGÜNDRAP',
        subtitle: 'Çizelge oluştur ve yönet',
        tone: DashboardActionTone.neutral,
        onTap: () => context.push('/temgundrap'),
      ),
      DashboardActionItem(
        icon: Icons.people_alt,
        title: 'Personel & Tim',
        subtitle: isAdmin ? 'Kayıt ve Yetki' : 'Kadro Durumu',
        tone: DashboardActionTone.personnel,
        onTap: () => context.push('/personnel-management'),
      ),
      if (isAdmin) ...[
        DashboardActionItem(
          icon: Icons.paste_rounded,
          title: 'Metinden Toplu Aktar',
          subtitle: 'WhatsApp / Liste Yükle',
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
          icon: Icons.image_search_rounded,
          title: 'Görselden Toplu Aktar',
          subtitle: 'OCR ile isim eşleştir',
          tone: DashboardActionTone.pending,
          onTap: () async {
            final service = RosterImageImportService();
            if (!service.isSupportedPlatform) {
              AppNotifications.warning(
                'Görselden aktarım Android ve iOS cihazlarda kullanılabilir.',
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
                ),
              );
              ref.invalidate(activityRepositoryProvider);
            } on RosterImageImportUnsupportedException catch (e) {
              AppNotifications.warning(e.toString());
            } on RosterImageImportNoNamesException catch (e) {
              AppNotifications.warning(e.toString());
            } on Object catch (e) {
              AppNotifications.error('Görsel okunamadı: $e');
            }
          },
        ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nizam'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ayarlar',
            onPressed: () => DashboardSettings.showSettingsBottomSheet(
              context,
              ref,
              session?.username ?? 'Kullanıcı',
              isAdmin,
            ),
          ),
        ],
      ),
      body: TurkishFlagWatermarkBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pendingList = pendingAsync.asData?.value ?? [];
            final hasWarningBanner = isAdmin && pendingList.isNotEmpty;

            final gridLayout = DashboardGridLayout.calculate(
              constraints,
              itemCount: gridActions.length,
              hasArchive: true,
              hasWarningBanner: hasWarningBanner,
            );

            return ResponsiveCenter(
              padding: gridLayout.padding,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  if (isAdmin)
                    SliverToBoxAdapter(
                      child: pendingAsync.when(
                        data: (pendingList) {
                          if (pendingList.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin: EdgeInsets.only(bottom: gridLayout.gap),
                            child: Card(
                              color: context.rejectedBgColor,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: context.rejectedBorderColor,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.warning_amber_rounded,
                                  color: context.rejectedColor,
                                  size: 28,
                                ),
                                title: Text(
                                  '${pendingList.length} Görevlendirmede Çakışma / Rapor Var!',
                                  style: TextStyle(
                                    color: context.rejectedColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                subtitle: Text(
                                  'Onaylamak veya reddetmek için dokunun.',
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 11.5,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: context.rejectedColor,
                                ),
                                onTap: () => context.push('/pending-approvals'),
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (err, st) => const SizedBox.shrink(),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: gridLayout.gap * 0.8),
                      child: Text(
                        'İşlemler',
                        style: TextStyle(
                          fontSize: gridLayout.gap < 10 ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridLayout.columnCount,
                      mainAxisExtent: gridLayout.mainAxisExtent,
                      crossAxisSpacing: gridLayout.gap,
                      mainAxisSpacing: gridLayout.gap,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                      childCount: gridActions.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: gridLayout.gap),
                  ),
                  SliverToBoxAdapter(
                    child: DashboardArchiveAction(
                      key: const ValueKey('dashboard-archive-action'),
                      icon: Icons.inventory_2_outlined,
                      title: 'Faaliyet Arşivi',
                      subtitle: 'Arama ve İnceleme',
                      height: gridLayout.archiveHeight,
                      animationIndex: gridActions.length,
                      onTap: () => context.push('/activity-archive'),
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
