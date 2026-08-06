import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';

class DashboardSettings {
  const DashboardSettings._();

  static Future<void> _showChangePasswordDialog(
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
                          content: const Text(
                            'Şifreniz başarıyla güncellendi!',
                          ),
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

  static void showSettingsBottomSheet(
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
                            final newMode =
                                value ? ThemeMode.dark : ThemeMode.light;
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
                              final count =
                                  await repo.seedTestPersonnelPerSquad();
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
}
