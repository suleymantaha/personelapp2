import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  final savedSession = await SessionStorage.loadSession();

  runApp(
    ProviderScope(
      overrides: [
        if (savedSession != null)
          userSessionProvider.overrideWith((ref) => savedSession),
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
