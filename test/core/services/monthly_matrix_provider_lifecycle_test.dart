import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';

class _TrackingMatrixRepository extends MatrixRepository {
  _TrackingMatrixRepository(super.db);

  int subscriptions = 0;
  int cancellations = 0;

  @override
  Stream<Map<int, Map<int, MatrixDayCell>>> watchMonthlyMatrix(
    String yearMonth, {
    int? timId,
    String? commanderUsername,
  }) {
    final controller = StreamController<Map<int, Map<int, MatrixDayCell>>>();
    controller.onListen = () {
      subscriptions++;
      controller.add({});
    };
    controller.onCancel = () {
      cancellations++;
      unawaited(controller.close());
    };
    return controller.stream;
  }
}

void main() {
  test('monthly matrix releases unused streams and reconnects on return',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repository = _TrackingMatrixRepository(db);
    final container = ProviderContainer(overrides: [
      matrixRepositoryProvider.overrideWithValue(repository),
      userSessionProvider.overrideWith(
        (ref) => const UserSessionState(
          username: 'test-admin',
          role: UserRole.admin,
        ),
      ),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final provider = monthlyMatrixProvider('2026-10');
    final first = container.listen(provider, (_, __) {});
    await container.read(provider.future);
    expect(repository.subscriptions, 1);
    expect(repository.cancellations, 0);

    first.close();
    await container.pump();
    expect(repository.cancellations, 1);

    final second = container.listen(provider, (_, __) {});
    await container.read(provider.future);
    expect(repository.subscriptions, 2);
    second.close();
    await container.pump();
    expect(repository.cancellations, 2);
  });
}
