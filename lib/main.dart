import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/core/notifications/app_notification_host.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  final database = AppDatabase();
  await database.ensureSeeded();

  final savedThemeMode = await SessionStorage.loadThemeMode();
  final initialSession = await SessionStorage.loadValidatedSession(database);

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        themeModeProvider.overrideWith((ref) => savedThemeMode),
        if (initialSession != null)
          userSessionProvider.overrideWith((ref) => initialSession),
      ],
      child: const PersonelApp(),
    ),
  );
}

class PersonelApp extends ConsumerWidget {
  const PersonelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Nizam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.militaryTheme,
      darkTheme: AppTheme.darkMilitaryTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => AppNotificationHost(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
