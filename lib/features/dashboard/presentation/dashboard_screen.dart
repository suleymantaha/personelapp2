import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_grid_layout.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_menu_card.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_settings.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;
    final pendingAsync = ref.watch(pendingAssignmentsProvider);

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
      body: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pending Approvals Warning Banner (Admin Only)
            if (isAdmin)
              pendingAsync.when(
                data: (pendingList) {
                  if (pendingList.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                          size: 32,
                        ),
                        title: Text(
                          '${pendingList.length} Görevlendirmede Çakışma / Rapor Var!',
                          style: TextStyle(
                            color: context.rejectedColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Onaylamak veya reddetmek için dokunun.',
                          style: TextStyle(color: context.textPrimary),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
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

            const Text(
              'İşlemler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Navigation Grid Cards
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemCount = isAdmin ? 7 : 5;
                  final gridLayout = DashboardGridLayout.calculate(
                    constraints,
                    itemCount,
                  );

                  return GridView.count(
                    crossAxisCount: gridLayout.columnCount,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.cardGap,
                    mainAxisSpacing: AppSpacing.cardGap,
                    childAspectRatio: gridLayout.cardAspectRatio,
                    children: <Widget>[
                      DashboardMenuCard(
                        icon: Icons.edit_calendar,
                        title: 'Faaliyet Çizelgesi',
                        subtitle: 'Günlük görev gir',
                        color: context.accentOrOlive,
                        onTap: () => context.push('/activity-form'),
                      ),
                      DashboardMenuCard(
                        icon: Icons.grid_on,
                        title: 'Aylık Matris',
                        subtitle: 'Excel / Dağıtım',
                        color: context.accentOrOlive,
                        onTap: () => context.push('/monthly-matrix'),
                      ),
                      DashboardMenuCard(
                        icon: Icons.table_chart_outlined,
                        title: 'TEMGÜNDRAP',
                        subtitle: 'Çizelge oluştur ve yönet',
                        color: context.accentOrOlive,
                        onTap: () => context.push('/temgundrap'),
                      ),
                      DashboardMenuCard(
                        icon: Icons.people_alt,
                        title: 'Personel & Tim',
                        subtitle: isAdmin ? 'Kayıt ve Yetki' : 'Kadro Durumu',
                        color: context.blueGreyColor,
                        onTap: () => context.push('/personnel-management'),
                      ),
                      if (isAdmin) ...[
                        DashboardMenuCard(
                          icon: Icons.paste_rounded,
                          title: 'Metinden Toplu Aktar',
                          subtitle: 'WhatsApp / Liste Yükle',
                          color: Colors.blue.shade700,
                          onTap: () async {
                            final db = ref.read(databaseProvider);
                            final activityRepo = ref.read(
                              activityRepositoryProvider,
                            );
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
                        DashboardMenuCard(
                          icon: Icons.assignment_turned_in,
                          title: 'Bekleyen Onaylar',
                          subtitle: 'Çakışma denetimi',
                          color: context.pendingColor,
                          onTap: () => context.push('/pending-approvals'),
                        ),
                      ],
                      DashboardMenuCard(
                        icon: Icons.inventory_2,
                        title: 'Faaliyet Arşivi',
                        subtitle: 'Arama ve İnceleme',
                        color: context.brownColor,
                        onTap: () => context.push('/activity-archive'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
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
          height: 150,
          child: DashboardMenuCard(
            icon: Icons.table_chart_outlined,
            title: 'TEMGÜNDRAP',
            subtitle: 'Çizelge oluştur ve yönet',
            color: Colors.green.shade800,
            onTap: _previewNoop,
          ),
        ),
      ),
    ),
  );
}

void _previewNoop() {}
