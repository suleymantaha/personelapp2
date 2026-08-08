import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:personelapp2/features/debt/services/offline_sync_service.dart';

import '../../../mocks/mock_annotations.mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late MockDebtRepository mockDebtRepo;
  late OfflineSyncService syncService;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDebtRepo = MockDebtRepository();
    syncService = OfflineSyncService(
      apiClient: mockApiClient,
      debtRepository: mockDebtRepo,
    );
  });

  group('Race Condition & Mutex Protection Tests', () {
    test('prevents concurrent sync execution when another sync is in progress', () async {
      when(mockApiClient.isNetworkConnected()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return true;
      });
      when(mockDebtRepo.loadLocalDebts()).thenAnswer((_) async => []);

      final sync1Future = syncService.synchronizePendingItems();
      final sync2Future = syncService.synchronizePendingItems();

      final results = await Future.wait([sync1Future, sync2Future]);

      final firstResult = results[0];
      final secondResult = results[1];

      final blockedResult = firstResult.error != null ? firstResult : secondResult;
      expect(blockedResult.isSuccess, isFalse);
      expect(blockedResult.error, contains('Race Condition engellendi'));
    });
  });
}
