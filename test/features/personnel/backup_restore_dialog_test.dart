import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/app_backup_service.dart';
import 'package:personelapp2/core/services/backup_file_gateway.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/backup_restore_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

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

        expect(find.text('Tam yedekleme ve geri yükleme'), findsOneWidget);
        expect(
          find.byType(width < 600 ? BottomSheet : Dialog),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('creates a full backup and sends it to the file gateway',
      (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final gateway = _FakeBackupFileGateway();
    await _pumpDialog(tester, database, gateway);

    await tester.ensureVisible(find.byKey(const Key('backup-create')));
    await tester.tap(find.byKey(const Key('backup-create')));
    await tester.pumpAndSettle();

    expect(gateway.savedContents, contains('"format": "nizam-full-backup"'));
    expect(find.text('Tam uygulama yedeği dışa aktarıldı.'), findsOneWidget);
  });

  testWidgets('validates a selected file and confirms destructive restore',
      (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final service = AppBackupService(database);
    final gateway = _FakeBackupFileGateway(
      openedContents: await service.exportBackupJson(),
    );
    await _pumpDialog(tester, database, gateway);

    await tester.tap(find.text('Geri yükle').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-pick-file')));
    await tester.pumpAndSettle();

    expect(find.text('Doğrulanmış tam yedek'), findsOneWidget);
    await tester.tap(find.byKey(const Key('backup-restore')));
    await tester.pumpAndSettle();
    expect(find.text('Mevcut veriler değiştirilsin mi?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('backup-confirm-restore')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Geri yükleme tamamlandı:'), findsOneWidget);
  });

  testWidgets('clipboard legacy backups remain supported', (tester) async {
    const backup = '{"version":1,"squads":[],"personnel":['
        '{"id":1,"adSoyad":"Test Personel","rutbe":"Astsubay",'
        '"birlik":"Merkez","timId":null,"kayitTarihi":"2026-07-30"}'
        '],"aliases":[]}';
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
    await _pumpDialog(tester, database, _FakeBackupFileGateway());

    await tester.tap(find.text('Geri yükle').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-paste')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-restore')));
    await tester.pumpAndSettle();

    expect(await database.select(database.personelTable).get(), hasLength(1));
    expect(find.textContaining('eski yedekten aktarıldı'), findsOneWidget);
  });

  testWidgets('validates formatted backup file with reordered keys picked from gateway',
      (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final service = AppBackupService(database);
    final exported = await service.exportBackupJson();

    // Pretty-print and reorder payload
    final Map<String, dynamic> decoded =
        jsonDecode(exported) as Map<String, dynamic>;
    final rawPayload = decoded['payload'] as Map<String, dynamic>;
    decoded['payload'] = <String, dynamic>{
      'preferences': rawPayload['preferences'],
      'tables': rawPayload['tables'],
      'databaseSchemaVersion': rawPayload['databaseSchemaVersion'],
    };
    final prettyJson = const JsonEncoder.withIndent('   ').convert(decoded);

    final gateway = _FakeBackupFileGateway(openedContents: prettyJson);
    await _pumpDialog(tester, database, gateway);

    await tester.tap(find.text('Geri yükle').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-pick-file')));
    await tester.pumpAndSettle();

    expect(find.text('Doğrulanmış tam yedek'), findsOneWidget);
    expect(find.textContaining('bütünlük kontrolü başarısız'), findsNothing);
  });
}

Future<void> _pumpDialog(
  WidgetTester tester,
  AppDatabase database,
  BackupFileGateway gateway,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BackupRestoreDialog(
          database: database,
          fileGateway: gateway,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeBackupFileGateway implements BackupFileGateway {
  _FakeBackupFileGateway({this.openedContents});

  final String? openedContents;
  String? savedContents;

  @override
  Future<String?> openBackup() async => openedContents;

  @override
  Future<bool> saveBackup(String contents, {Rect? shareOrigin}) async {
    savedContents = contents;
    return true;
  }
}
