import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: '123456');
  String _selectedRole = 'yönetici';

  Future<void> _showPasswordCreationDialog(String username, KullaniciTableData user) async {
    final pass1Ctrl = TextEditingController();
    final pass2Ctrl = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('İlk Giriş: Parola Belirleyin'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sayın $username, hesabınız için yeni bir parola belirleyiniz.',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
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
                    Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    final p1 = pass1Ctrl.text.trim();
                    final p2 = pass2Ctrl.text.trim();

                    if (p1.isEmpty || p1.length < 4) {
                      setDialogState(() => errorText = 'Parola en az 4 karakter olmalıdır.');
                      return;
                    }
                    if (p1 != p2) {
                      setDialogState(() => errorText = 'Parolalar eşleşmiyor!');
                      return;
                    }

                    final repo = ref.read(personnelRepositoryProvider);
                    await repo.updateUserPassword(kullaniciAdi: username, newPassword: p1);

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
  }

  Future<void> _loginUserSession(KullaniciTableData user) async {
    final db = ref.read(databaseProvider);
    var timId = user.timId;
    if (user.rol == 'tim_komutani' && timId == null) {
      final squad = await (db.select(db.timTable)
            ..where((tbl) => tbl.timKomutaniId.equals(user.id)))
          .getSingleOrNull();
      timId = squad?.id;
    }

    ref.read(userSessionProvider.notifier).state = UserSessionState(
      username: user.kullaniciAdi,
      role: user.rol,
      timId: timId,
    );

    if (mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty) return;

    final db = ref.read(databaseProvider);
    final user = await (db.select(db.kullaniciTable)
          ..where((tbl) => tbl.kullaniciAdi.equals(username)))
        .getSingleOrNull();

    if (user != null) {
      if (user.sifre.isEmpty) {
        // First-time login: Password not set yet
        await _showPasswordCreationDialog(username, user);
        return;
      }

      if (user.sifre == password) {
        await _loginUserSession(user);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Geçersiz kullanıcı adı veya parola!')),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.security,
                    size: 64,
                    color: AppColors.militaryOlive,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Jandarma Görev Takip',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.militaryOlive,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Giriş Portalı',
                    style: TextStyle(color: Colors.grey),
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı Rolü',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'yönetici',
                        child: Text('Birlik Yöneticisi (Admin)'),
                      ),
                      DropdownMenuItem(
                        value: 'tim_komutani',
                        child: Text('Tim Komutanı'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedRole = val);
                      }
                    },
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
    );
  }
}
