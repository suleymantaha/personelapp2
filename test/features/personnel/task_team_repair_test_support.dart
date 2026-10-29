import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/backup_file_gateway.dart';
import 'package:personelapp2/core/services/task_team_repair_service.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/task_team_repair_dialog.dart';

const admin = UserSessionState(username: 'test-admin', role: UserRole.admin);
const commander =
    UserSessionState(username: 'test-commander', role: UserRole.teamCommander);

class RepairHarness {
  final db = AppDatabase(NativeDatabase.memory());
  late final service = FakeRepairService(db);
  final gateway = FakeRepairGateway();
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester,
      {UserSessionState? actor = admin}) async {
    container =
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    container.read(userSessionProvider.notifier).state = actor;
    addTearDown(container.dispose);
    addTearDown(db.close);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                        onPressed: () => showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => TaskTeamRepairDialog(
                                database: db,
                                service: service,
                                fileGateway: gateway)),
                        child: const Text('open'),
                      )))),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> verify(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('repair-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repair-verify')));
    await tester.pumpAndSettle();
  }
}

class FakeRepairService extends TaskTeamRepairService {
  FakeRepairService(super.db);
  int prepares = 0;
  int applies = 0;
  bool empty = false;
  bool stale = false;
  Completer<int>? pending;
  UserSessionState? appliedActor;

  @override
  Future<TaskTeamRepairPreview> prepare(UserSessionState actor) async {
    prepares++;
    return FakePreview(empty);
  }

  @override
  Future<int> apply(
      {required TaskTeamRepairPreview preview,
      required String verifiedBackupJson,
      required UserSessionState actor}) async {
    applies++;
    appliedActor = actor;
    if (stale) throw StateError('private database contents');
    return pending?.future ?? 1;
  }
}

class FakePreview implements TaskTeamRepairPreview {
  FakePreview(this.empty);
  final bool empty;
  @override
  String get backupJson => '{"synthetic":"backup"}';
  @override
  List<TaskTeamRepairCandidate> get candidates =>
      empty ? [] : [FakeCandidate()];
  @override
  int get unknownCount => 2;
  @override
  int get outsideCount => 1;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCandidate implements TaskTeamRepairCandidate {
  @override
  int get assignmentId => 11;
  @override
  int get activityId => 22;
  @override
  int get personnelId => 33;
  @override
  String get date => '2026-10-01';
  @override
  int get teamId => 44;
  @override
  String get teamName => 'Test Tim';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRepairGateway implements BackupFileGateway {
  bool saveResult = true;
  bool failSave = false;
  String? reopened = '{"synthetic":"backup"}';
  int saves = 0;
  int opens = 0;
  bool failOpen = false;
  @override
  Future<bool> saveBackup(String contents, {Rect? shareOrigin}) async {
    saves++;
    if (failSave) throw StateError('private file contents');
    return saveResult;
  }

  @override
  Future<String?> openBackup() async {
    opens++;
    if (failOpen) throw StateError('private file contents');
    return reopened;
  }
}
