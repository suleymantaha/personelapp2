import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppDatabase? appDatabase;
  UserSessionState? savedSession;
  ThemeMode savedThemeMode = ThemeMode.light;

  try {
    await initializeDateFormatting('tr_TR');
  } catch (e) {
    debugPrint('DateFormatting init error: $e');
  }

  try {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dbFolder.path, 'jandarma_app.sqlite'));
    appDatabase = AppDatabase(NativeDatabase(dbFile));
  } catch (e) {
    debugPrint('Database init error: $e');
    appDatabase = AppDatabase();
  }

  try {
    savedSession = await SessionStorage.loadSession().timeout(
      const Duration(seconds: 3),
      onTimeout: () => null,
    );
  } catch (e) {
    debugPrint('Session load error: $e');
  }

  try {
    savedThemeMode = await SessionStorage.loadThemeMode().timeout(
      const Duration(seconds: 2),
      onTimeout: () => ThemeMode.light,
    );
  } catch (e) {
    debugPrint('Theme load error: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(appDatabase),
        if (savedSession != null)
          userSessionProvider.overrideWith((ref) => savedSession),
        themeModeProvider.overrideWith((ref) => savedThemeMode),
      ],
      child: PersonelApp(hasActiveSession: savedSession != null),
    ),
  );
}

class PersonelApp extends ConsumerWidget {
  const PersonelApp({required this.hasActiveSession, super.key});

  final bool hasActiveSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Jandarma Görev Takip Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.militaryTheme,
      darkTheme: AppTheme.darkMilitaryTheme,
      themeMode: themeMode,
      routerConfig: createAppRouter(hasActiveSession: hasActiveSession),
    );
  }
}
