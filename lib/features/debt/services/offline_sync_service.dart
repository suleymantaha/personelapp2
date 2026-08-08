import 'dart:async';
import '../../../core/network/api_client.dart';
import '../data/debt_repository.dart';
import '../domain/debt_models.dart';

class SyncResult {
  final int syncedCount;
  final bool isSuccess;
  final String? error;

  const SyncResult({
    required this.syncedCount,
    required this.isSuccess,
    this.error,
  });
}

class OfflineSyncService {
  final ApiClient apiClient;
  final DebtRepository debtRepository;
  bool _isSyncing = false;

  OfflineSyncService({
    required this.apiClient,
    required this.debtRepository,
  });

  bool get isSyncing => _isSyncing;

  Future<SyncResult> synchronizePendingItems() async {
    if (_isSyncing) {
      return const SyncResult(
        syncedCount: 0,
        isSuccess: false,
        error: 'Senkronizasyon zaten devam ediyor (Race Condition engellendi).',
      );
    }

    _isSyncing = true;
    int syncedCount = 0;

    try {
      final isConnected = await apiClient.isNetworkConnected();
      if (!isConnected) {
        _isSyncing = false;
        return const SyncResult(
          syncedCount: 0,
          isSuccess: false,
          error: 'İnternet bağlantısı mevcut değil.',
        );
      }

      final debts = await debtRepository.loadLocalDebts();
      final unsynced = debts.where((d) => !d.isSynced).toList();

      if (unsynced.isEmpty) {
        _isSyncing = false;
        return const SyncResult(syncedCount: 0, isSuccess: true);
      }

      final updatedDebts = List<DebtItem>.from(debts);

      for (final debt in unsynced) {
        try {
          await apiClient.post('/debts/sync', body: debt.toJson());
          final index = updatedDebts.indexWhere((d) => d.id == debt.id);
          if (index >= 0) {
            updatedDebts[index] = updatedDebts[index].copyWith(isSynced: true);
            syncedCount++;
          }
        } catch (_) {
          // Skip failed item for retry on next sync pass
        }
      }

      await debtRepository.saveLocalDebts(updatedDebts);
      _isSyncing = false;
      return SyncResult(syncedCount: syncedCount, isSuccess: true);
    } catch (e) {
      _isSyncing = false;
      return SyncResult(syncedCount: syncedCount, isSuccess: false, error: e.toString());
    }
  }
}
