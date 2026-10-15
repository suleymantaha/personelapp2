import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/widgets/roster_signer_dialog.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';

Widget preview() => ProviderScope(
      child: MaterialApp(
          home: RosterOutputPreviewScreen(
        date: '2026-10-10',
        sources: const [],
        rows: const [],
        loadRows: () async => [],
      )),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('failed saving keeps the editor open and allows retry',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RosterSignerDialog(
      signer: const RosterSigner('TANZİM EDEN', 'Test', 'Rütbe', 'Görev'),
      onSave: (_) async {
        attempts++;
        throw StateError('storage unavailable');
      },
    ))));
    await tester.tap(find.byKey(const Key('save-roster-signer')));
    await tester.pumpAndSettle();
    expect(find.byType(RosterSignerDialog), findsOneWidget);
    expect(find.text('İmza bilgileri kaydedilemedi. Tekrar deneyin.'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('save-roster-signer')));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });
  testWidgets('blank name cannot replace a saved signer', (tester) async {
    await tester.pumpWidget(preview());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-roster-signer-0')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signer-name')), '   ');
    await tester.tap(find.byKey(const Key('save-roster-signer')));
    await tester.pumpAndSettle();
    expect(find.byType(RosterSignerDialog), findsOneWidget);
    expect(find.text('Lütfen ad soyad giriniz.'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('roster_signers_v1'), isFalse);
  });
  testWidgets('saved signer fields survive reopening the preview',
      (tester) async {
    await tester.pumpWidget(preview());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-roster-signer-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('signer-name')), 'Yeni Tanzim Eden');
    await tester.enterText(find.byKey(const Key('signer-rank')), 'Yeni Rütbe');
    await tester.enterText(find.byKey(const Key('signer-role')), 'Yeni Görev');
    await tester.tap(find.byKey(const Key('save-roster-signer')));
    await tester.pumpAndSettle();
    expect(find.text('Yeni Tanzim Eden'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(preview());
    await tester.pumpAndSettle();
    expect(find.text('Yeni Tanzim Eden'), findsOneWidget);
    expect(find.text('Yeni Rütbe'), findsOneWidget);
    expect(find.text('Yeni Görev'), findsOneWidget);
    expect(find.text('Serdar YILDIZ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('cancelling signer changes preserves the previous values',
      (tester) async {
    await tester.pumpWidget(preview());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-roster-signer-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('signer-name')), 'Kaydedilmeyecek');
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(find.text('Kaydedilmeyecek'), findsNothing);
    expect(find.text('Serdar YILDIZ'), findsOneWidget);
  });
}
