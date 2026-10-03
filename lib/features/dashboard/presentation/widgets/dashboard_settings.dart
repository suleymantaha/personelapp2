import 'package:personelapp2/core/utils/password_policy.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/backup_restore_dialog.dart';

class DashboardSettings {
  const DashboardSettings._();

  static Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
    String username,
  ) async {
    final passCtrl = TextEditingController();
    bool saving = false;
    String? errorText;
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder:
                (ctx, updateDialog) => PopScope(
                  canPop: !saving,
                  child: AlertDialog(
                    title: const Text('Şifremi Değiştir'),
                    content: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Kullanıcı: $username',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: passCtrl,
                              obscureText: true,
                              decoration: InputDecoration(
                                errorText: errorText,
                                labelText: 'Yeni Şifreniz',
                                prefixIcon: const Icon(Icons.lock),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed:
                            saving ? null : () => Navigator.of(ctx).pop(),
                        child: const Text('İPTAL'),
                      ),
                      ElevatedButton(
                        onPressed:
                            saving
                                ? null
                                : () async {
                                  final newPass = passCtrl.text.trim();
                                  if (!PasswordPolicy.isValid(newPass)) {
                                    updateDialog(
                                      () => errorText = PasswordPolicy.message,
                                    );
                                    return;
                                  }
                                  updateDialog(() {
                                    saving = true;
                                    errorText = null;
                                  });
                                  try {
                                    final changed = await ref
                                        .read(personnelRepositoryProvider)
                                        .updateUserPassword(
                                          kullaniciAdi: username,
                                          newPassword: newPass,
                                        );
                                    if (changed != 1) {
                                      throw StateError('Kullanıcı bulunamadı.');
                                    }
                                    if (ctx.mounted) {
                                      updateDialog(() => saving = false);
                                      await WidgetsBinding.instance.endOfFrame;
                                      if (!ctx.mounted) return;
                                      Navigator.of(ctx).pop();
                                      AppNotifications.success(
                                        'Şifreniz başarıyla güncellendi!',
                                      );
                                    }
                                  } catch (error) {
                                    if (ctx.mounted) {
                                      updateDialog(
                                        () =>
                                            errorText =
                                                'Şifre güncellenemedi: $error',
                                      );
                                    }
                                  } finally {
                                    if (ctx.mounted) {
                                      updateDialog(() => saving = false);
                                    }
                                  }
                                },
                        child: const Text('GÜNCELLE'),
                      ),
                    ],
                  ),
                ),
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
          return Consumer(
            builder: (ctx, ref, _) {
              final themeMode = ref.watch(themeModeProvider);

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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    themeMode == ThemeMode.dark
                                        ? Icons.dark_mode
                                        : (themeMode == ThemeMode.light
                                            ? Icons.light_mode
                                            : Icons.brightness_auto),
                                    color: context.accentOrOlive,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Uygulama Teması',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<ThemeMode>(
                                  segments: const [
                                    ButtonSegment<ThemeMode>(
                                      value: ThemeMode.light,
                                      label: Text('Açık'),
                                      icon: Icon(Icons.light_mode_outlined),
                                    ),
                                    ButtonSegment<ThemeMode>(
                                      value: ThemeMode.dark,
                                      label: Text('Koyu'),
                                      icon: Icon(Icons.dark_mode_outlined),
                                    ),
                                    ButtonSegment<ThemeMode>(
                                      value: ThemeMode.system,
                                      label: Text('Sistem'),
                                      icon: Icon(Icons.brightness_auto),
                                    ),
                                  ],
                                  selected: {themeMode},
                                  onSelectionChanged: (
                                    Set<ThemeMode> selection,
                                  ) async {
                                    final newMode = selection.first;
                                    ref.read(themeModeProvider.notifier).state =
                                        newMode;
                                    await SessionStorage.saveThemeMode(newMode);
                                  },
                                ),
                              ),
                            ],
                          ),
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
                              Icons.storage_rounded,
                              color: context.accentOrOlive,
                            ),
                            title: const Text('Tam Yedekleme'),
                            subtitle: const Text(
                              'Tüm uygulama verilerini cihazda sakla veya geri yükle',
                            ),
                            onTap: () async {
                              Navigator.pop(ctx);
                              final restored = await showBackupRestoreSurface(
                                context: context,
                                database: ref.read(databaseProvider),
                              );
                              if (restored) {
                                ref.invalidate(allPersonnelProvider);
                                ref.invalidate(allSquadsProvider);
                                ref.invalidate(allCommandersProvider);
                                ref.invalidate(filteredActivitiesProvider);
                                ref.invalidate(pendingAssignmentsProvider);
                              }
                            },
                          ),
                          if (kDebugMode)
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
                                  AppNotifications.success(
                                    '$count adet test personeli başarıyla eklendi!',
                                  );
                                }
                              },
                            ),
                          if (kDebugMode)
                            ListTile(
                              leading: Icon(
                                Icons.delete_sweep,
                                color: context.rejectedColor,
                              ),
                              title: Text(
                                'Test Personellerini Temizle',
                                style: TextStyle(color: context.rejectedColor),
                              ),
                              subtitle: const Text(
                                'Yalnızca işaretlenmiş test personellerini temizler',
                              ),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (dCtx) => AlertDialog(
                                        title: const Text('Personelleri Sil'),
                                        content: const Text(
                                          'Yalnızca test olarak işaretlenmiş personel kayıtları silinecektir. Emin misiniz?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.pop(dCtx, false),
                                            child: const Text('İPTAL'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  context.rejectedColor,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed:
                                                () => Navigator.pop(dCtx, true),
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
                                    AppNotifications.info(
                                      'İşaretlenmiş test personelleri temizlendi!',
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
