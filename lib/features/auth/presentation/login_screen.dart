import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/utils/password_hasher.dart';

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
          session = await SessionStorage.loadSession();
          if (session != null) {
            ref.read(userSessionProvider.notifier).state = session;
          }
        } on Exception catch (_) {}
      }

      if (session != null && mounted) {
        context.go('/dashboard');
      }
    });
  }

  Future<void> _showPasswordCreationDialog(
    String username,
    KullaniciTableData user,
  ) async {
    final pass1Ctrl = TextEditingController();
    final pass2Ctrl = TextEditingController();
    String? errorText;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                title: const Text('İlk Giriş: Parola Belirleyin'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sayın $username, hesabınız için yeni bir parola belirleyiniz.',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: pass1Ctrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Yeni Parola',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pass2Ctrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Yeni Parola (Tekrar)',
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorText!,
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
                    onPressed: () async {
                      final p1 = pass1Ctrl.text.trim();
                      final p2 = pass2Ctrl.text.trim();

                      if (p1.length < 12) {
                        setDialogState(
                          () => errorText =
                              'Parola en az 12 karakter olmalıdır.',
                        );
                        return;
                      }
                      if (p1 != p2) {
                        setDialogState(() => errorText = 'Parolalar eşleşmiyor!');
                        return;
                      }

                      final repo = ref.read(personnelRepositoryProvider);
                      await repo.updateUserPassword(
                        kullaniciAdi: username,
                        newPassword: p1,
                      );

                      if (ctx.mounted) Navigator.of(ctx).pop();

                      await _loginUserSession(user);
                    },
                    child: const Text('PAROLAYI KAYDET VE GİRİŞ YAP'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      pass1Ctrl.dispose();
      pass2Ctrl.dispose();
    }
  }

  Future<void> _loginUserSession(KullaniciTableData user) async {
    final db = ref.read(databaseProvider);
    var timId = user.timId;
    if (user.rol == 'tim_komutani' && timId == null) {
      final squad = await (db.select(
        db.timTable,
      )..where((tbl) => tbl.timKomutaniId.equals(user.id))).getSingleOrNull();
      timId = squad?.id;
    }

    final session = UserSessionState(
      username: user.kullaniciAdi,
      role: user.rol,
      timId: timId,
    );

    await SessionStorage.saveSession(session);
    ref.read(userSessionProvider.notifier).state = session;

    if (mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty) return;

    final db = ref.read(databaseProvider);
    final user = await (db.select(
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geçersiz kullanıcı adı veya parola!'),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçersiz kullanıcı adı veya parola!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final outerPadding = context.responsiveValue<EdgeInsetsGeometry>(
      mobile: const EdgeInsets.all(16),
      desktop: const EdgeInsets.all(24),
    );
    final cardPadding = context.responsiveValue<EdgeInsetsGeometry>(
      mobile: const EdgeInsets.all(20),
      desktop: const EdgeInsets.all(32),
    );

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: outerPadding,
          child: ResponsiveCenter(
            maxWidth: 440,
            padding: EdgeInsets.zero,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                      'Jandarma Görev Takip',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.accentOrOlive,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Giriş Portalı',
                      style: context.textStyleSecondary,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı Adı',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        child: const Text('GİRİŞ YAP'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
