import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/backup_restore_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [320.0, 400.0, 800.0]) {
    testWidgets(
      'backup surface uses ${width < 600 ? 'bottom sheet' : 'dialog'} '
      'at ${width.toInt()} px',
      (tester) async {
        tester.view
          ..physicalSize = Size(width, 900)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => showBackupRestoreSurface(
                    context: context,
                    database: database,
                  ),
                  child: const Text('Yedeklemeyi aç'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Yedeklemeyi aç'));
        await tester.pumpAndSettle();

        expect(find.text('Yedekleme ve geri yükleme'), findsOneWidget);
        if (width < 600) {
          expect(find.byType(BottomSheet), findsOneWidget);
          expect(find.byType(Dialog), findsNothing);
        } else {
          expect(find.byType(Dialog), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('keyboard inset keeps backup text field usable', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: BackupRestoreDialog(
              database: database,
              isBottomSheet: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('backup-text-field')), findsOneWidget);
    expect(
        tester.getSize(find.byKey(const Key('backup-text-field'))).height, 150);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clipboard paste restores a valid backup', (tester) async {
    const backup = '{"version":1,"squads":[],"personnel":[{"id":1,'
        '"adSoyad":"Test Personel","rutbe":"Astsubay","birlik":"Merkez",'
        '"timId":null,"kayitTarihi":"2026-07-30"}],"aliases":[]}';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, Object?>{'text': backup};
      }
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BackupRestoreDialog(database: database)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geri yükle'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-paste')));
    await tester.pump();
    expect(find.text(backup), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('backup-restore')));
    await tester.tap(find.byKey(const Key('backup-restore')));
    await tester.pumpAndSettle();

    expect(find.text('1 yeni personel ve tim kaydı içe aktarıldı.'),
        findsOneWidget);
    expect(await database.select(database.personelTable).get(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('generated backup can be copied to clipboard', (tester) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText =
            (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BackupRestoreDialog(database: database)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('backup-create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-copy')));
    await tester.pump();

    expect(copiedText, contains('"version": 1'));
    expect(find.text('Yedek metni panoya kopyalandı.'), findsOneWidget);
  });
}
