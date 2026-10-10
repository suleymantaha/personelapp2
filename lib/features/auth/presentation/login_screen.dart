import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/utils/password_policy.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/utils/password_hasher.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final db = ref.read(databaseProvider);
        await db.ensureSeeded();
      } on Exception catch (_) {}

      var session = ref.read(userSessionProvider);
      if (session == null) {
        try {
          final db = ref.read(databaseProvider);
          session = await SessionStorage.loadValidatedSession(db);
          if (session != null) {
            ref.read(userSessionProvider.notifier).state = session;
          }
        } on Exception catch (_) {}
      }

      if (session != null && mounted) {
        AppNavigator.toDashboard(context);
      }
    });
  }

  Future<void> _showPasswordCreationDialog(
    String username,
    KullaniciTableData user,
  ) async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PasswordCreationDialog(username: username),
    );
    if (password == null || !mounted) return;

    final repo = ref.read(personnelRepositoryProvider);
    await repo.updateUserPassword(
      kullaniciAdi: username,
      newPassword: password,
    );
    await _loginUserSession(user);
  }

  Future<void> _loginUserSession(KullaniciTableData user) async {
    final l10n = context.l10n;
    final db = ref.read(databaseProvider);
    var timId = user.timId;
    if (user.rol == 'tim_komutani' && timId == null) {
      final squad =
          await (db.select(db.timTable)..where(
            (tbl) => tbl.timKomutaniId.equals(user.id),
          )).getSingleOrNull();
      timId = squad?.id;
    }

    final role = UserRole.fromStorageValue(user.rol);
    if (role == null) {
      throw StateError(l10n.authUnsupportedRole(user.rol));
    }
    final session = UserSessionState(
      username: user.kullaniciAdi,
      role: role,
      timId: timId,
    );

    await SessionStorage.saveSession(session);
    ref.read(userSessionProvider.notifier).state = session;

    if (mounted) {
      AppNavigator.toDashboard(context);
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty) return;

    final db = ref.read(databaseProvider);
    final user =
        await (db.select(
          db.kullaniciTable,
        )..where((tbl) => tbl.kullaniciAdi.equals(username))).getSingleOrNull();

    if (user != null) {
      if (user.sifre.isEmpty) {
        // First-time login: Password not set yet
        await _showPasswordCreationDialog(username, user);
        return;
      }

      final verification = await PasswordHasher.verifyPassword(
        password,
        user.sifre,
        username: user.kullaniciAdi,
      );
      if (verification.matches) {
        if (verification.needsRehash) {
          final repo = ref.read(personnelRepositoryProvider);
          await repo.updateUserPassword(
            kullaniciAdi: user.kullaniciAdi,
            newPassword: password,
          );
        }
        await _loginUserSession(user);
      } else {
        if (mounted) {
          AppNotifications.error(context.l10n.authInvalidCredentials);
        }
      }
    } else {
      if (mounted) {
        AppNotifications.error(context.l10n.authInvalidCredentials);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final outerPadding = context.responsiveValue<EdgeInsetsGeometry>(
      mobile: const EdgeInsets.all(AppSpacing.pagePadding),
      desktop: const EdgeInsets.all(AppSpacing.widePagePadding),
    );
    final cardPadding = context.responsiveValue<EdgeInsetsGeometry>(
      mobile: const EdgeInsets.all(AppSpacing.pagePadding),
      desktop: const EdgeInsets.all(AppSpacing.xl),
    );

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: TurkishFlagWatermarkBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: outerPadding,
            child: ResponsiveCenter(
              maxWidth: 440,
              padding: EdgeInsets.zero,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Padding(
                  padding: cardPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.security,
                        size: 64,
                        color: context.accentOrOlive,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nizam',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.accentOrOlive,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        context.l10n.authMissionManagement,
                        style: context.textStyleSecondary,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: context.l10n.authUsername,
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.authPassword,
                          prefixIcon: const Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          child: Text(context.l10n.authLoginButton),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordCreationDialog extends StatefulWidget {
  const _PasswordCreationDialog({required this.username});

  final String username;

  @override
  State<_PasswordCreationDialog> createState() =>
      _PasswordCreationDialogState();
}

class _PasswordCreationDialogState extends State<_PasswordCreationDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text.trim();
    final confirmation = _confirmationController.text.trim();

    if (!PasswordPolicy.isValid(password)) {
      setState(() => _errorText = PasswordPolicy.message);
      return;
    }
    if (password != confirmation) {
      setState(() => _errorText = context.l10n.authPasswordsDoNotMatch);
      return;
    }

    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.authFirstLoginTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.authFirstLoginSubtitle(widget.username),
              style: TextStyle(fontSize: 13, color: context.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.l10n.authNewPassword,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmationController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.l10n.authNewPasswordRepeat,
                prefixIcon: const Icon(Icons.lock_reset),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: TextStyle(
                  color: context.colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _submit,
          child: Text(context.l10n.authSavePasswordAndLogin),
        ),
      ],
    );
  }
}
