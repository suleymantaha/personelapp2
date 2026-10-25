import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/database/connection/storage_unavailable.dart';
import 'package:personelapp2/core/database/startup_database.dart';

void main() {
  test('failed open and failed close still return the startup failure',
      () async {
    const failure = StorageUnavailable();
    final database = AppDatabase(LazyDatabase(() async => throw failure));
    expect(await prepareDatabase(database), same(failure));
  });
}
