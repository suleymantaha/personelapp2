import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
    String username,
  ) async {
    final passCtrl = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Şifremi Değiştir'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kullanıcı: $username',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Yeni Şifreniz',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('İPTAL'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newPass = passCtrl.text.trim();
                  if (newPass.length >= 4) {
                    final repo = ref.read(personnelRepositoryProvider);
                    await repo.updateUserPassword(
                      kullaniciAdi: username,
                      newPassword: newPass,
                    );
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: const Text('Şifreniz başarıyla güncellendi!'),
                          backgroundColor: context.approvedColor,
                        ),
                      );
                    }
                  }
                },
                child: const Text('GÜNCELLE'),
              ),
            ],
          );
        },
      );
    } finally {
      passCtrl.dispose();
    }
  }

  void _showSettingsBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String username,
    bool isAdmin,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setSheetState) {
              final themeMode = ref.watch(themeModeProvider);
              final isDarkMode = themeMode == ThemeMode.dark;

              return SafeArea(
                child: ResponsiveCenter(
                  maxWidth: 600,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: context.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: context.accentOrOlive,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            'Hesap: $username',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isAdmin
                                ? 'Rol: Birlik Yöneticisi (Admin)'
                                : 'Rol: Tim Komutanı',
                          ),
                        ),
                        const Divider(),
                        SwitchListTile(
                          secondary: Icon(
                            isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: context.accentOrOlive,
                          ),
                          title: const Text('Koyu Mod (Dark Theme)'),
                          subtitle: Text(isDarkMode ? 'Aktif' : 'Pasif'),
                          value: isDarkMode,
                          onChanged: (value) async {
                            final newMode = value
                                ? ThemeMode.dark
                                : ThemeMode.light;
                            ref.read(themeModeProvider.notifier).state =
                                newMode;
                            await SessionStorage.saveThemeMode(newMode);
                            setSheetState(() {});
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.key,
                            color: context.accentOrOlive,
                          ),
                          title: const Text('Şifremi Değiştir'),
                          onTap: () {
                            Navigator.pop(ctx);
                            unawaited(
                              _showChangePasswordDialog(context, ref, username),
                            );
                          },
                        ),
                        if (isAdmin) ...[
                          const Divider(),
                          ListTile(
                            leading: Icon(
                              Icons.group_add,
                              color: context.accentOrOlive,
                            ),
                            title: const Text("10'ar Test Personeli Ekle"),
                            subtitle: const Text(
                              'Her time 10 adet sahte personel oluşturur',
                            ),
                            onTap: () async {
                              Navigator.pop(ctx);
                              final repo = ref.read(
                                personnelRepositoryProvider,
                              );
                              final count = await repo
                                  .seedTestPersonnelPerSquad();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$count adet test personeli başarıyla eklendi!',
                                    ),
                                    backgroundColor: context.approvedColor,
                                  ),
                                );
                              }
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.delete_sweep,
                              color: context.rejectedColor,
                            ),
                            title: Text(
                              'Tüm Personelleri Sil (Sıfırla)',
                              style: TextStyle(color: context.rejectedColor),
                            ),
                            subtitle: const Text(
                              'Eklenen tüm personelleri temizler',
                            ),
                            onTap: () async {
                              Navigator.pop(ctx);
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  title: const Text('Personelleri Sil'),
                                  content: const Text(
                                    'Veritabanındaki tüm personel kayıtları silinecektir. Emin misiniz?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dCtx, false),
                                      child: const Text('İPTAL'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.rejectedColor,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(dCtx, true),
                                      child: const Text('SİL'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final repo = ref.read(
                                  personnelRepositoryProvider,
                                );
                                await repo.deleteAllPersonnel();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Tüm personel verileri temizlendi!',
                                      ),
                                      backgroundColor: context.approvedColor,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],

                        ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: context.rejectedColor,
                          ),
                          title: Text(
                            'Çıkış Yap',
                            style: TextStyle(color: context.rejectedColor),
                          ),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await SessionStorage.clearSession();
                            ref.read(userSessionProvider.notifier).state = null;
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? true;
    final pendingAsync = ref.watch(pendingAssignmentsProvider);

    final crossAxisCount = context.gridCrossAxisCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jandarma Görev Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ayarlar',
            onPressed: () => _showSettingsBottomSheet(
              context,
              ref,
              session?.username ?? 'Kullanıcı',
              isAdmin,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
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
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: context.responsiveValue(
                  mobile: 1.2,
                  tablet: 1.25,
                  desktop: 1.35,
                ),
                children: [
                  _MenuCard(
                    icon: Icons.edit_calendar,
                    title: 'Faaliyet Çizelgesi',
                    subtitle: 'Günlük görev gir',
                    color: context.accentOrOlive,
                    onTap: () => context.push('/activity-form'),
                  ),
                  _MenuCard(
                    icon: Icons.grid_on,
                    title: 'Aylık Matris',
                    subtitle: 'Excel / Dağıtım',
                    color: context.accentOrOlive,
                    onTap: () => context.push('/monthly-matrix'),
                  ),
                  _MenuCard(
                    icon: Icons.people_alt,
                    title: 'Personel & Tim',
                    subtitle: isAdmin ? 'Kayıt ve Yetki' : 'Kadro Durumu',
                    color: context.blueGreyColor,
                    onTap: () => context.push('/personnel-management'),
                  ),
                  if (isAdmin) ...[
                    _MenuCard(
                      icon: Icons.paste_rounded,
                      title: 'Metinden Toplu Aktar',
                      subtitle: 'WhatsApp / Liste Yükle',
                      color: Colors.blue.shade700,
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
                    _MenuCard(
                      icon: Icons.group_add,
                      title: 'Yeni Tim Ekle',
                      subtitle: 'Tim & Komutan Ekle',
                      color: context.tealColor,
                      onTap: () => context.push('/personnel-management'),
                    ),
                    _MenuCard(
                      icon: Icons.assignment_turned_in,
                      title: 'Bekleyen Onaylar',
                      subtitle: 'Çakışma denetimi',
                      color: context.pendingColor,
                      onTap: () => context.push('/pending-approvals'),
                    ),
                  ],
                  _MenuCard(
                    icon: Icons.inventory_2,
                    title: 'Faaliyet Arşivi',
                    subtitle: 'Arama ve İnceleme',
                    color: context.brownColor,
                    onTap: () => context.push('/activity-archive'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: color.withValues(alpha: context.isDarkMode ? 0.18 : 0.1),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: color.withValues(alpha: context.isDarkMode ? 0.4 : 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
