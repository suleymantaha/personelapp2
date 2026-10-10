import 'package:personelapp2/core/utils/password_policy.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
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
                    title: Text(context.l10n.settingsChangePassword),
                    content: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.l10n.settingsUserAccount(username),
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
                                labelText: context.l10n.settingsNewPassword,
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
                        child: Text(context.l10n.commonCancel.toUpperCase()),
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
                                  final l10n = context.l10n;
                                  try {
                                    final changed = await ref
                                        .read(personnelRepositoryProvider)
                                        .updateUserPassword(
                                          kullaniciAdi: username,
                                          newPassword: newPass,
                                        );
                                    if (changed != 1) {
                                      throw StateError(l10n.settingsUserNotFound);
                                    }
                                    if (ctx.mounted) {
                                      updateDialog(() => saving = false);
                                      await WidgetsBinding.instance.endOfFrame;
                                      if (!ctx.mounted) return;
                                      Navigator.of(ctx).pop();
                                      AppNotifications.success(
                                        l10n.settingsPasswordUpdated,
                                      );
                                    }
                                  } catch (error) {
                                    if (ctx.mounted) {
                                      updateDialog(
                                        () =>
                                            errorText =
                                                context.l10n.settingsPasswordUpdateFailed('$error'),
                                      );
                                    }
                                  } finally {
                                    if (ctx.mounted) {
                                      updateDialog(() => saving = false);
                                    }
                                  }
                                },
                        child: Text(context.l10n.settingsUpdate),
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
                            context.l10n.settingsUserAccount(username),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isAdmin
                                ? context.l10n.settingsRoleAdmin
                                : context.l10n.settingsRoleCommander,
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
                                    context.l10n.settingsAppTheme,
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
                                  segments: [
                                    ButtonSegment<ThemeMode>(
                                      value: ThemeMode.light,
                                      label: Text(context.l10n.settingsThemeLight),
                                      icon: const Icon(Icons.light_mode_outlined),
                                    ),
                                    ButtonSegment<ThemeMode>(
                                      value: ThemeMode.dark,
                                      label: Text(context.l10n.settingsThemeDark),
                                      icon: const Icon(Icons.dark_mode_outlined),
                                    ),
                                    ButtonSegment<ThemeMode>(
                                      value: ThemeMode.system,
                                      label: Text(context.l10n.settingsThemeSystem),
                                      icon: const Icon(Icons.brightness_auto),
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
                          title: Text(context.l10n.settingsChangePassword),
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
                            title: Text(context.l10n.settingsFullBackup),
                            subtitle: Text(
                              context.l10n.settingsFullBackupSubtitle,
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
                              title: Text(context.l10n.settingsAddTestPersonnelTitle),
                              subtitle: Text(
                                context.l10n.settingsAddTestPersonnelSubtitle,
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
                                    context.l10n.settingsTestPersonnelAddedSuccess(count),
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
                                context.l10n.settingsClearTestPersonnelTitle,
                                style: TextStyle(color: context.rejectedColor),
                              ),
                              subtitle: Text(
                                context.l10n.settingsClearTestPersonnelSubtitle,
                              ),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (dCtx) => AlertDialog(
                                        title: Text(context.l10n.settingsDeletePersonnelConfirmTitle),
                                        content: Text(
                                          context.l10n.settingsDeleteTestPersonnelConfirmMessage,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.pop(dCtx, false),
                                            child: Text(context.l10n.commonCancel.toUpperCase()),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  context.rejectedColor,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed:
                                                () => Navigator.pop(dCtx, true),
                                            child: Text(context.l10n.commonDelete.toUpperCase()),
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
                                      context.l10n.settingsTestPersonnelCleared,
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
                            context.l10n.authLogoutButton,
                            style: TextStyle(color: context.rejectedColor),
                          ),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await SessionStorage.clearSession();
                            ref.read(userSessionProvider.notifier).state = null;
                            if (context.mounted) {
                              AppNavigator.toLogin(context);
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
