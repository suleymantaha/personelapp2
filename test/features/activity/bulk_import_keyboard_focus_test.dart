import 'package:personelapp2/core/providers/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_input_section.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'source editor keeps focus and pasted text through keyboard metric changes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      final database = AppDatabase(NativeDatabase.memory());
      await database.into(database.kullaniciTable).insert(
          KullaniciTableCompanion.insert(
              kullaniciAdi: 'admin', rol: 'yönetici'));
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSessionProvider.overrideWith((ref) =>
                const UserSessionState(username: 'admin', role: UserRole.admin))
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BulkImportDialog(
                database: database,
                activityRepository: ActivityRepository(database),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final source = find.byKey(const Key('bulk-import-source-text-field'));
      expect(source, findsOneWidget);
      final originalState = tester.state<EditableTextState>(
        find.descendant(of: source, matching: find.byType(EditableText)),
      );

      await tester.showKeyboard(source);
      await tester.pumpAndSettle();
      final focusNode = tester.widget<TextField>(source).focusNode!;
      expect(focusNode.hasFocus, isTrue);

      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      await tester.pumpAndSettle();
      expect(source, findsOneWidget);
      expect(focusNode.hasFocus, isTrue);
      expect(
        identical(
          originalState,
          tester.state<EditableTextState>(
            find.descendant(of: source, matching: find.byType(EditableText)),
          ),
        ),
        isTrue,
      );

      final pasted = [
        '16.10.2026 — 1-B Hazır Kıta',
        for (var i = 1; i <= 120; i++) '$i- J.Uzm.Çvş. Örnek Personel $i',
      ].join('\n');
      await tester.enterText(source, pasted);
      await tester.pump();
      expect(tester.widget<TextField>(source).controller!.text, pasted);
      expect(focusNode.hasFocus, isTrue);

      tester.view.viewInsets = const FakeViewPadding(bottom: 0);
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
      expect(tester.widget<TextField>(source).controller!.text, pasted);

      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
      expect(tester.widget<TextField>(source).controller!.text, pasted);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'advanced preferences are collapsed even when audit storage is enabled',
    (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkImportInputSection(
              textController: controller,
              textFocusNode: focusNode,
              keepAuditText: true,
              onKeepAuditTextChanged: (_) {},
              isMobile: true,
              isKeyboardVisible: false,
              isParsing: false,
              onProcessText: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tile = tester.widget<ExpansionTile>(find.byType(ExpansionTile));
      expect(tile.initiallyExpanded, isFalse);
      expect(find.text('Gelişmiş seçenekler'), findsOneWidget);
      expect(
        find.text('Ham metni yerel denetim kaydında sakla'),
        findsNothing,
      );
      await tester.tap(find.text('Gelişmiş seçenekler'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ham metni yerel denetim kaydında sakla'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
