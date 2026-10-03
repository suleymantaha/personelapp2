import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/backup_file_gateway.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/activity_assignment_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/add_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/transfer_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/transfer_squad_dialog.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/backup_restore_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _source = GunlukFaaliyetTableData(
  id: 1,
  faaliyetAdi: 'Kaynak',
  tarih: '2026-10-03',
  olusturanKullanici: 'admin',
  olusturmaTarihi: '2026-10-03',
);
const _target = GunlukFaaliyetTableData(
  id: 2,
  faaliyetAdi: 'Hedef',
  tarih: '2026-10-03',
  olusturanKullanici: 'admin',
  olusturmaTarihi: '2026-10-03',
);
const _person = PersonelTableData(
  id: 1,
  adSoyad: 'Ahmet Yılmaz',
  rutbe: 'J.Asb.',
  birlik: '1. Tim',
  timId: 1,
  kayitTarihi: '2026-10-03',
  aktif: true,
  isDemo: false,
);

Future<AppDatabase> _database(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  await db.customSelect('SELECT 1').get();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
  return db;
}

Future<void> _open(
  WidgetTester tester,
  AppDatabase db,
  Future<void> Function(BuildContext) open,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        userSessionProvider.overrideWith(
          (ref) =>
              const UserSessionState(username: 'admin', role: UserRole.admin),
        ),
        allPersonnelProvider.overrideWith((ref) => Stream.value([_person])),
        historicalPersonnelProvider.overrideWith(
          (ref) => Stream.value([_person]),
        ),
        allSquadsProvider.overrideWith(
          (ref) => Stream.value(const [
            TimTableData(
              id: 1,
              timAdi: '1. Tim',
              olusturmaTarihi: '2026-10-03',
            ),
          ]),
        ),
        filteredActivitiesProvider.overrideWith(
          (ref) => Stream.value([_source, _target]),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => open(context),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Aç'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final details in [false, true]) {
    testWidgets('close asks before discarding personnel at details=$details', (
      tester,
    ) async {
      final db = await _database(tester);
      bool? result;
      await _open(tester, db, (context) async {
        result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const AddPersonnelToActivityDialog(
              activity: _source,
              isAdmin: true,
              existingPersonnelIds: {},
            ),
          ),
        );
      });
      await tester.tap(find.byKey(const Key('personnel-option-1')));
      await tester.pumpAndSettle();
      if (details) {
        await tester.tap(find.text('Devam et'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Kapat'));
      await tester.pumpAndSettle();
      expect(find.text('Değişikliklerden vazgeçilsin mi?'), findsOneWidget);
      await tester.tap(find.text('DÜZENLEMEYE DEVAM ET'));
      await tester.pumpAndSettle();
      expect(find.byType(AddPersonnelToActivityDialog), findsOneWidget);
      await tester.tap(find.byTooltip('Kapat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('VAZGEÇ VE ÇIK'));
      await tester.pumpAndSettle();
      expect(find.byType(AddPersonnelToActivityDialog), findsNothing);
      expect(find.text('Aç'), findsOneWidget);
      expect(result, false);
      expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final saveSuccess in [false, true]) {
    testWidgets('preview waits for save before back, success=$saveSuccess', (
      tester,
    ) async {
      final db = await _database(tester);
      final save = Completer<bool>();
      addTearDown(() {
        if (!save.isCompleted) save.complete(false);
      });
      bool? result;
      await _open(tester, db, (context) async {
        result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ActivityAssignmentPreviewScreen(
              activityName: 'Test',
              date: DateTime(2026, 10, 3),
              preview: const ActivityAssignmentPreview(
                squadNames: {},
                items: [],
              ),
              requiresAdminApproval: false,
              onConfirm: () => save.future,
            ),
          ),
        );
      });
      await tester.tap(find.byKey(const Key('preview-confirm-button')));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(ActivityAssignmentPreviewScreen), findsOneWidget);
      save.complete(saveSuccess);
      await tester.pumpAndSettle();
      if (!saveSuccess) {
        expect(find.byType(ActivityAssignmentPreviewScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      } else {
        expect(result, true);
      }
      expect(find.byType(ActivityAssignmentPreviewScreen), findsNothing);
      expect(find.text('Aç'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final squad in [false, true]) {
    testWidgets('transfer protects pending transaction, squad=$squad', (
      tester,
    ) async {
      final db = await _database(tester);
      await _open(tester, db, (context) async {
        if (squad) {
          await showTransferSquadDialog(
            context,
            sourceActivity: _source,
            squadId: 1,
            squadName: '1. Tim',
          );
        } else {
          await showTransferPersonnelDialog(
            context,
            assignment: const FaaliyetPersonelAtamaTableData(
              id: 1,
              faaliyetId: 1,
              personelId: 1,
              gorevVeyaIzin: 'GÖREVLİ',
              durum: 'onaylandi',
            ),
            sourceActivity: _source,
            personnelDisplayName: 'Ahmet Yılmaz',
          );
        }
      });
      await tester.tap(
        find.byKey(
          Key(squad ? 'transfer-target-2' : 'personnel-transfer-target-2'),
        ),
      );
      await tester.pumpAndSettle();
      final entered = Completer<void>();
      final release = Completer<void>();
      final transaction = db.transaction(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      try {
        await tester.tap(
          find.byKey(
            Key(
              squad ? 'transfer-squad-confirm' : 'personnel-transfer-confirm',
            ),
          ),
        );
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(milliseconds: 350));
        expect(
          find.byType(squad ? TransferSquadDialog : TransferPersonnelDialog),
          findsOneWidget,
        );
        // The dismissible barrier must obey the same guard as system back.
        await tester.tapAt(const Offset(5, 5));
        await tester.pump(const Duration(milliseconds: 350));
        expect(
          find.byType(squad ? TransferSquadDialog : TransferPersonnelDialog),
          findsOneWidget,
        );
      } finally {
        release.complete();
        await transaction;
        await tester.pumpAndSettle();
      }
      expect(find.text('Aç'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final dismiss in ['close', 'back', 'barrier']) {
    testWidgets('backup stays open during file save: $dismiss', (tester) async {
      final db = await _database(tester);
      final gateway = _PendingBackupGateway();
      addTearDown(() {
        if (!gateway.saved.isCompleted) gateway.saved.complete(false);
      });
      await _open(tester, db, (context) async {
        await showDialog<void>(
          context: context,
          builder: (_) =>
              BackupRestoreDialog(database: db, fileGateway: gateway),
        );
      });
      await tester.ensureVisible(find.byKey(const Key('backup-create')));
      await tester.tap(find.byKey(const Key('backup-create')));
      await tester.runAsync(
        () => gateway.started.future.timeout(const Duration(seconds: 5)),
      );
      await tester.pump();
      if (dismiss == 'close') {
        await tester.tap(find.byIcon(Icons.close_rounded));
      } else if (dismiss == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tapAt(const Offset(5, 5));
      }
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(BackupRestoreDialog), findsOneWidget);
      gateway.saved.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Tam uygulama yedeği dışa aktarıldı.'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(BackupRestoreDialog), findsNothing);
      expect(find.text('Aç'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _PendingBackupGateway implements BackupFileGateway {
  final started = Completer<void>();
  final saved = Completer<bool>();
  @override
  Future<bool> saveBackup(String contents, {Rect? shareOrigin}) {
    started.complete();
    return saved.future;
  }

  @override
  Future<String?> openBackup() async => null;
}
