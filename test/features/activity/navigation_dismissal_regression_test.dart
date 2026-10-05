import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/features/activity/presentation/activity_form_screen.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/backup_file_gateway.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/activity_assignment_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/add_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/bulk_personnel_import_dialog.dart';
import 'package:personelapp2/features/personnel/presentation/widgets/personnel_form_dialog.dart';
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
  await db
      .into(db.timTable)
      .insert(
        const TimTableData(
          id: 1,
          timAdi: '1. Tim',
          olusturmaTarihi: '2026-10-03',
        ).toCompanion(true),
      );
  await db.into(db.personelTable).insert(_person.toCompanion(true));
  await db.into(db.gunlukFaaliyetTable).insert(_source.toCompanion(true));
  await db.into(db.gunlukFaaliyetTable).insert(_target.toCompanion(true));
  addTearDown(db.close);
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

void _navigationTest(
  String description,
  Future<void> Function(WidgetTester) body,
) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } finally {
      // Unmount and drain Drift's deferred stream disposal before the binding
      // checks pending timers; teardown callbacks run after that check.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 10));
    }
  });
}

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final systemBack in [false, true]) {
    _navigationTest(
      'real router returns from details and closes form: system=$systemBack',
      (tester) async {
        final db = await _database(tester);
        const session = UserSessionState(
          username: 'admin',
          role: UserRole.admin,
        );
        final router = createAppRouter(session: session);
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              userSessionProvider.overrideWith((ref) => session),
              allPersonnelProvider.overrideWith(
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
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        unawaited(router.push('/activity-form'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('squad-select-1. Tim')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('continue-to-details-button')));
        await tester.pumpAndSettle();
        Future<void> back() async {
          if (systemBack) {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(find.byType(BackButton));
          }
          await tester.pumpAndSettle();
        }

        await back();
        expect(
          find.byKey(const Key('personnel-selection-step')),
          findsOneWidget,
        );
        await back();
        expect(find.text('Değişiklikler silinsin mi?'), findsOneWidget);
        await tester.tap(find.text('Devam et'));
        await tester.pumpAndSettle();
        expect(find.byType(ActivityFormScreen), findsOneWidget);
        await back();
        await tester.tap(find.text('Çık'));
        await tester.pumpAndSettle();
        expect(find.byType(ActivityFormScreen), findsNothing);
        expect(router.routeInformationProvider.value.uri.path, '/dashboard');
        expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final details in [false, true]) {
    _navigationTest(
      'close asks before discarding personnel at details=$details',
      (tester) async {
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
        await tester.enterText(
          find.byKey(const Key('personnel-search-field')),
          'yilmaz',
        );
        await tester.pumpAndSettle();
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
      },
    );
  }

  for (final saveSuccess in [false, true]) {
    _navigationTest(
      'preview waits for save before back, success=$saveSuccess',
      (tester) async {
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
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();
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
      },
    );
  }

  for (final squad in [false, true]) {
    _navigationTest('transfer protects pending transaction, squad=$squad', (
      tester,
    ) async {
      final db = await _database(tester);
      await db
          .into(db.faaliyetPersonelAtamaTable)
          .insert(
            const FaaliyetPersonelAtamaTableData(
              id: 1,
              faaliyetId: 1,
              personelId: 1,
              gorevVeyaIzin: 'GÖREVLİ',
              durum: 'onaylandi',
              gorevTimId: 1,
              gorevTimAdi: '1. Tim',
            ).toCompanion(true),
          );
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
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();
        expect(
          find.byType(squad ? TransferSquadDialog : TransferPersonnelDialog),
          findsOneWidget,
        );
        // The dismissible barrier must obey the same guard as system back.
        await tester.tapAt(const Offset(5, 5));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();
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

  for (final surface in ['personnel', 'personnel-import', 'activity-import']) {
    for (final dismiss in ['button', 'back', 'barrier']) {
      _navigationTest('$surface protects pending save from $dismiss', (
        tester,
      ) async {
        final db = await _database(tester);
        await _open(tester, db, (context) async {
          await showDialog<Object?>(
            context: context,
            builder: (_) {
              if (surface == 'personnel') {
                return const PersonnelFormDialog(personnelToEdit: _person);
              }
              if (surface == 'personnel-import') {
                return const BulkPersonnelImportDialog();
              }
              return BulkImportDialog(
                database: db,
                activityRepository: ActivityRepository(db),
                targetActivity: _source,
              );
            },
          );
        });
        Finder saveButton;
        if (surface == 'personnel') {
          await tester.enterText(
            find.widgetWithText(TextField, 'Ad Soyad'),
            'Ahmet Güncel',
          );
          saveButton = find.text('GÜNCELLE');
        } else if (surface == 'personnel-import') {
          await tester.enterText(
            find.byKey(const Key('bulk-personnel-text-field')),
            '1. J.Asb.Çvş. Mehmet KAYA',
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const Key('bulk-personnel-preview-button')),
          );
          await tester.pumpAndSettle();
          saveButton = find.byKey(const Key('bulk-personnel-save-button'));
        } else {
          await tester.enterText(
            find.byType(TextField).first,
            '03.10.2026\n1. Tim HEYBET\n1- J.Asb. Ahmet YILMAZ',
          );
          await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Kaydet'));
          await tester.pumpAndSettle();
          saveButton = find.byKey(const Key('bulk-import-save-button'));
        }
        await tester.ensureVisible(saveButton);
        final entered = Completer<void>();
        final release = Completer<void>();
        final transaction = db.transaction(() async {
          entered.complete();
          await release.future;
        });
        await entered.future;
        try {
          await tester.tap(saveButton);
          await tester.pump();
          if (dismiss == 'back') {
            await tester.binding.handlePopRoute();
          } else if (dismiss == 'barrier') {
            await tester.tapAt(const Offset(5, 5));
          } else if (surface == 'activity-import') {
            await tester.tap(find.byIcon(Icons.close));
          } else {
            await tester.tap(find.text('İPTAL'));
          }
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pump();
          expect(
            find.byType(
              surface == 'personnel'
                  ? PersonnelFormDialog
                  : surface == 'personnel-import'
                  ? BulkPersonnelImportDialog
                  : BulkImportDialog,
            ),
            findsOneWidget,
          );
        } finally {
          release.complete();
          await transaction;
          if (surface == 'activity-import') {
            // The import stays busy until its result dialog is acknowledged.
            // Settling an intentionally running progress indicator would hang.
            for (
              var frame = 0;
              frame < 50 && find.text('Aktarım Tamamlandı').evaluate().isEmpty;
              frame++
            ) {
              await tester.pump(const Duration(milliseconds: 20));
            }
          } else {
            await tester.pumpAndSettle();
          }
        }
        if (surface == 'activity-import') {
          expect(find.text('Aktarım Tamamlandı'), findsOneWidget);
          await tester.tap(find.text('TAMAM'));
          await tester.pumpAndSettle();
          expect(
            await db.select(db.faaliyetPersonelAtamaTable).get(),
            hasLength(1),
          );
        } else if (surface == 'personnel') {
          expect(
            (await db.select(db.personelTable).get()).single.adSoyad,
            'Ahmet Güncel',
          );
        } else {
          expect(await db.select(db.personelTable).get(), hasLength(2));
        }
        expect(find.text('Aç'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final dismiss in ['close', 'back', 'barrier']) {
    _navigationTest('backup stays open during file save: $dismiss', (
      tester,
    ) async {
      final db = await _database(tester);
      final gateway = _PendingBackupGateway();
      addTearDown(() {
        if (!gateway.saved.isCompleted) gateway.saved.complete(false);
      });
      await _open(tester, db, (context) async {
        await showDialog<Object?>(
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
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
