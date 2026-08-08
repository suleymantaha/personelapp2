import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        allPersonnelProvider.overrideWith(
          (ref) => Stream.value(const <PersonelTableData>[]),
        ),
        allSquadsProvider.overrideWith(
          (ref) => Stream.value(const <TimTableData>[]),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Widget createTestWidget() {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: TemgundrapScreen(),
      ),
    );
  }

  group('Temgundrap Screen Widget Data Exchange & Interaction Tests', () {
    testWidgets('renders temgundrap screen with draft report structure', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(TemgundrapScreen), findsOneWidget);
    });
  });
}
