import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    setState(() => _errorMessage = null);

    try {
      // 1. Initialize Locale Formatting
      try {
        await initializeDateFormatting('tr_TR').timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      } catch (e) {
        debugPrint('Locale init error: $e');
      }

      // 2. Initialize Database and seed safely with timeout
      try {
        final db = ref.read(databaseProvider);
        await db.ensureSeeded().timeout(
          const Duration(seconds: 3),
          onTimeout: () {},
        );
      } catch (e) {
        debugPrint('DB seeding error fallback: $e');
      }

      // 3. Load Session safely with timeout
      UserSessionState? session;
      try {
        session = await SessionStorage.loadSession().timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
      } catch (e) {
        debugPrint('Session load error: $e');
      }

      if (session != null) {
        ref.read(userSessionProvider.notifier).state = session;
      }

      // 4. Load Theme Mode safely with timeout
      try {
        final themeMode = await SessionStorage.loadThemeMode().timeout(
          const Duration(seconds: 2),
          onTimeout: () => ThemeMode.light,
        );
        ref.read(themeModeProvider.notifier).state = themeMode;
      } catch (e) {
        debugPrint('Theme load error: $e');
      }

      // Small delay for smooth UI transition
      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        if (session != null) {
          context.go('/dashboard');
        } else {
          context.go('/login');
        }
      }
    } catch (e, st) {
      debugPrint('Initialization error: $e\n$st');
      if (mounted) {
        setState(() {
          _errorMessage = 'Uygulama başlatılırken bir sorun oluştu ($e).';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: context.accentSubtleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security,
                  size: 52,
                  color: context.accentOrOlive,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Jandarma Görev Takip',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.accentOrOlive,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sistem Başlatılıyor...',
                style: context.textStyleSecondary,
              ),
              const SizedBox(height: 40),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: context.rejectedColor,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _initializeApp,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accentOrOlive,
                    foregroundColor: context.onAccentOrOlive,
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: context.accentOrOlive,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
