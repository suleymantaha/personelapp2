import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  runApp(
    const ProviderScope(
      child: PersonelApp(),
    ),
  );
}

class PersonelApp extends StatelessWidget {
  const PersonelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jandarma Görev Takip Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.militaryTheme,
      routerConfig: appRouter,
    );
  }
}
