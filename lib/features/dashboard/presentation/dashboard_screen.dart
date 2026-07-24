import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
    String username,
  ) async {
    final passCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Şifremi Değiştir'),
          content: ConstrainedBox(
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
                      const SnackBar(
                        content: Text('Şifreniz başarıyla güncellendi!'),
                        backgroundColor: AppColors.approvedGreen,
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
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
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.militaryOlive,
                          child: Icon(Icons.person, color: Colors.white),
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
                          color: AppColors.militaryOlive,
                        ),
                        title: const Text('Koyu Mod (Dark Theme)'),
                        subtitle: Text(isDarkMode ? 'Aktif' : 'Pasif'),
                        value: isDarkMode,
                        onChanged: (value) {
                          ref.read(themeModeProvider.notifier).state = value
                              ? ThemeMode.dark
                              : ThemeMode.light;
                          setSheetState(() {});
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.key,
                          color: AppColors.militaryOlive,
                        ),
                        title: const Text('Şifremi Değiştir'),
                        onTap: () {
                          Navigator.pop(ctx);
                          unawaited(
                            _showChangePasswordDialog(context, ref, username),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: AppColors.rejectedRed,
                        ),
                        title: const Text(
                          'Çıkış Yap',
                          style: TextStyle(color: AppColors.rejectedRed),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(userSessionProvider.notifier).state = null;
                          context.go('/login');
                        },
                      ),
                    ],
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
          maxWidth: 1200,
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
                        color: context.isDarkMode
                            ? AppColors.warningBackgroundDark
                            : AppColors.warningBackgroundLight,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: context.isDarkMode
                                ? AppColors.warningBorderDark
                                : AppColors.warningBorderLight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.rejectedRed,
                            size: 32,
                          ),
                          title: Text(
                            '${pendingList.length} Görevlendirmede Çakışma / Rapor Var!',
                            style: const TextStyle(
                              color: AppColors.rejectedRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Onaylamak veya reddetmek için dokunun.',
                            style: TextStyle(color: context.textPrimary),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.rejectedRed,
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
                  mobile: 1.1,
                  tablet: 1.2,
                  desktop: 1.3,
                ),
                children: [
                  _MenuCard(
                    icon: Icons.edit_calendar,
                    title: 'Faaliyet Çizelgesi',
                    subtitle: 'Günlük görev gir',
                    color: AppColors.militaryOlive,
                    onTap: () => context.push('/activity-form'),
                  ),
                  _MenuCard(
                    icon: Icons.grid_on,
                    title: 'Aylık Matris',
                    subtitle: 'Excel / Dağıtım',
                    color: AppColors.accentKhaki,
                    onTap: () => context.push('/monthly-matrix'),
                  ),
                  _MenuCard(
                    icon: Icons.people_alt,
                    title: 'Personel & Tim',
                    subtitle: isAdmin ? 'Kayıt ve Yetki' : 'Kadro Durumu',
                    color: AppColors.cardBlueGrey,
                    onTap: () => context.push('/personnel-management'),
                  ),
                  if (isAdmin) ...[
                    _MenuCard(
                      icon: Icons.group_add,
                      title: 'Yeni Tim Ekle',
                      subtitle: 'Tim & Komutan Ekle',
                      color: AppColors.cardTeal,
                      onTap: () => context.push('/personnel-management'),
                    ),
                    _MenuCard(
                      icon: Icons.assignment_turned_in,
                      title: 'Bekleyen Onaylar',
                      subtitle: 'Çakışma denetimi',
                      color: AppColors.pendingYellow,
                      onTap: () => context.push('/pending-approvals'),
                    ),
                  ],
                  _MenuCard(
                    icon: Icons.inventory_2,
                    title: 'Faaliyet Arşivi',
                    subtitle: 'Arama ve İnceleme',
                    color: AppColors.cardBrown,
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
        color: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
