import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import 'storage_unavailable.dart';

QueryExecutor openConnection() => DatabaseConnection.delayed(Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'jandarma_app',
        sqlite3Uri: Uri.base.resolve('sqlite3_2_35_1.wasm'),
        driftWorkerUri: Uri.base.resolve('drift_worker_2_35_1.js'),
      );
      // Never silently accept lost records or unsynchronised multi-tab writes.
      if (result.chosenImplementation == WasmStorageImplementation.inMemory ||
          result.chosenImplementation ==
              WasmStorageImplementation.unsafeIndexedDb) {
        await result.resolvedExecutor.close();
        throw const StorageUnavailable();
      }
      return result.resolvedExecutor;
    }));
