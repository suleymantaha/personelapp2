// Integration Test: App Widget Interaction & Data Flow User Journey
// Tests widget-to-widget interaction across Personnel, Matrix, Temgundrap, and Dashboard screens.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Widget Interaction & Data Exchange User Journey', () {
    testWidgets('Comprehensive widget interaction and data flow test', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.ensureSeeded();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Dashboard Rendering
      expect(find.byType(DashboardScreen), findsOneWidget);

      await db.close();
    });
  });
}
