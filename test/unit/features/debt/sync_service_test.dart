import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:personelapp2/features/debt/domain/debt_models.dart';
import 'package:personelapp2/features/debt/services/offline_sync_service.dart';

import '../../../mocks/mock_annotations.mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late MockDebtRepository mockDebtRepo;
  late OfflineSyncService syncService;

  final unsyncedDebt = DebtItem(
    id: 'd_unsynced',
    debtorName: 'Cemil Taş',
    totalAmount: 300.0,
    remainingAmount: 300.0,
    createdAt: DateTime.now(),
    isSynced: false,
  );

  setUp(() {
    mockApiClient = MockApiClient();
    mockDebtRepo = MockDebtRepository();
    syncService = OfflineSyncService(
      apiClient: mockApiClient,
      debtRepository: mockDebtRepo,
    );
  });

  group('OfflineSyncService Unit Tests', () {
    test('returns failure when network is disconnected', () async {
      when(mockApiClient.isNetworkConnected()).thenAnswer((_) async => false);

      final result = await syncService.synchronizePendingItems();

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('bağlantısı mevcut değil'));
      verifyNever(mockDebtRepo.loadLocalDebts());
    });

    test('synchronizes pending items when network is online', () async {
      when(mockApiClient.isNetworkConnected()).thenAnswer((_) async => true);
      when(mockDebtRepo.loadLocalDebts()).thenAnswer((_) async => [unsyncedDebt]);
      when(mockApiClient.post('/debts/sync', body: anyNamed('body'))).thenAnswer(
        (_) async => {'status': 'ok'},
      );
      when(mockDebtRepo.saveLocalDebts(any)).thenAnswer((_) async {});

      final result = await syncService.synchronizePendingItems();

      expect(result.isSuccess, isTrue);
      expect(result.syncedCount, equals(1));
      verify(mockApiClient.post('/debts/sync', body: anyNamed('body'))).called(1);
      verify(mockDebtRepo.saveLocalDebts(any)).called(1);
    });

    test('handles empty unsynced queue gracefully', () async {
      when(mockApiClient.isNetworkConnected()).thenAnswer((_) async => true);
      when(mockDebtRepo.loadLocalDebts()).thenAnswer((_) async => [unsyncedDebt.copyWith(isSynced: true)]);

      final result = await syncService.synchronizePendingItems();

      expect(result.isSuccess, isTrue);
      expect(result.syncedCount, equals(0));
      verifyNever(mockApiClient.post('/debts/sync', body: anyNamed('body')));
    });
  });
}
