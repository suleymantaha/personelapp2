import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  final savedThemeMode = await SessionStorage.loadThemeMode();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((ref) => savedThemeMode),
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
    );
  }
}
