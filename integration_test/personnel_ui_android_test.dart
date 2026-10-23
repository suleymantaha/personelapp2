import 'dart:io';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/personnel/presentation/personnel_management_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android personnel search and inline order acceptance',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
    final team = (await db.select(db.timTable).get()).first.id;
    for (final name in [
      'Ali YILMAZ',
      'Mehmet DEMİR',
      'Ahmet KAYA',
      'Emre ÇELİK'
    ]) {
      await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
          adSoyad: name,
          rutbe: 'J.Asb.Kd.Bçvş.',
          birlik: 'Örnek',
          kayitTarihi: '',
          timId: Value(team)));
    }
    await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((ref) =>
              const UserSessionState(username: 'admin', role: UserRole.admin)),
        ],
        child: MaterialApp(
            theme: AppTheme.darkMilitaryTheme,
            home: const PersonnelManagementScreen())));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final bytes = await binding.takeScreenshot(name);
      final dir = await getTemporaryDirectory();
      await File('${dir.path}/$name.png').writeAsBytes(bytes);
    }

    expect(find.byType(TextField), findsNothing);
    await capture('personnel-collapsed');
    await tester.tap(find.byKey(ValueKey('team-header-$team')));
    await tester.pumpAndSettle();
    await capture('personnel-expanded');
    await tester.tap(find.byKey(const ValueKey('personnel-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mehmet');
    await tester.pumpAndSettle();
    expect(find.text('Mehmet DEMİR'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('personnel-search-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-personnel-order')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('order-team-$team')));
    await tester.pumpAndSettle();
    await capture('personnel-order');
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      await Future<void>.delayed(const Duration(seconds: 25));
    }
    expect(find.text('Kaydet'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await db.close();
  });
}
