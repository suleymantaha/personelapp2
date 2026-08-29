import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/edit_activity_block_dialog.dart';

void main() {
  testWidgets(
      'EditActivityBlockDialog allows selecting duty via chips and dropdown',
      (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final block = ParsedActivityBlock(
      rawTitle: 'Test Card',
      parsedTimName: '6-B',
      parsedActivityType: 'Eski Görev',
      parsedDate: '2026-08-03',
      personnelList: [],
    );

    ParsedActivityBlock? resultBlock;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  resultBlock =
                      await EditActivityBlockDialog.show(context, block);
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Faaliyet kartını düzenle'), findsOneWidget);
    expect(find.text('Hızlı Görev Seçimi'), findsOneWidget);
    expect(find.text('HAZIR KITA'), findsOneWidget);

    // Tap quick chip "HAZIR KITA"
    await tester.tap(find.text('HAZIR KITA'));
    await tester.pumpAndSettle();

    // Tap save button
    await tester.tap(find.byKey(const Key('bulk-edit-save')));
    await tester.pumpAndSettle();

    expect(resultBlock, isNotNull);
    expect(resultBlock!.parsedActivityType, DutyOrLeaveType.hazirKita);
  });

  testWidgets(
      'EditActivityBlockDialog allows selecting team via team dropdown',
      (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final block = ParsedActivityBlock(
      rawTitle: 'Test Card',
      parsedTimName: '',
      parsedActivityType: 'HEYBET',
      parsedDate: '2026-08-03',
      personnelList: [],
    );

    final availableSquads = [
      const TimTableData(
        id: 1,
        timAdi: '6-B Timi',
        olusturmaTarihi: '2026-01-01',
      ),
      const TimTableData(
        id: 2,
        timAdi: '7-B Timi',
        olusturmaTarihi: '2026-01-01',
      ),
    ];

    ParsedActivityBlock? resultBlock;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  resultBlock = await EditActivityBlockDialog.show(
                    context,
                    block,
                    availableSquads: availableSquads,
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bulk-edit-team-dropdown')), findsOneWidget);

    // Tap team dropdown and select "6-B Timi"
    await tester.tap(find.byKey(const Key('bulk-edit-team-dropdown')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('6-B Timi').last);
    await tester.pumpAndSettle();

    // Tap save button
    await tester.tap(find.byKey(const Key('bulk-edit-save')));
    await tester.pumpAndSettle();

    expect(resultBlock, isNotNull);
    expect(resultBlock!.parsedTimName, '6-B Timi');
  });

  testWidgets(
      'EditActivityBlockDialog does not auto-fill missing date or duty',
      (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final block = ParsedActivityBlock(
      rawTitle: 'Eksik Kart',
      parsedTimName: '',
      parsedActivityType: '',
      parsedDate: '',
      personnelList: [],
    );

    ParsedActivityBlock? resultBlock;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  resultBlock =
                      await EditActivityBlockDialog.show(context, block);
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Tarih seç'), findsOneWidget);
    expect(find.text('HEYBET'), findsOneWidget);
    expect(find.text('Görev / Faaliyet Adı (Elle Düzenle)'), findsOneWidget);

    final saveButton =
        tester.widget<FilledButton>(find.byKey(const Key('bulk-edit-save')));
    expect(saveButton.onPressed, isNull);

    await tester.tap(find.text('HEYBET'));
    await tester.pumpAndSettle();

    final stillDisabled =
        tester.widget<FilledButton>(find.byKey(const Key('bulk-edit-save')));
    expect(stillDisabled.onPressed, isNull);
    expect(resultBlock, isNull);
  });

  testWidgets('faaliyet kartı düzenleme klavye açıkken taşma yapmaz',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final block = ParsedActivityBlock(
      rawTitle: 'Test Card',
      parsedTimName: '6-B',
      parsedActivityType: 'HEYBET',
      parsedDate: '2026-08-03',
      personnelList: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EditActivityBlockDialog.show(context, block),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsWidgets);
    expect(find.byKey(const Key('bulk-edit-activity')), findsOneWidget);
  });
}
