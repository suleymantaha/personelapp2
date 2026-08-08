import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:personelapp2/features/debt/domain/debt_models.dart';
import 'package:personelapp2/features/debt/presentation/providers/debt_notifier.dart';

import '../../../mocks/mock_annotations.mocks.dart';

void main() {
  late MockDebtRepository mockRepo;
  late MockOfflineSyncService mockSyncService;
  late DebtNotifier debtNotifier;

  final testDebt = DebtItem(
    id: 'd1',
    debtorName: 'Ahmet Yılmaz',
    totalAmount: 1000.0,
    remainingAmount: 1000.0,
    createdAt: DateTime.now(),
    status: DebtStatus.active,
    installments: [
      InstallmentPlan(
        installmentNumber: 1,
        amount: 500.0,
        dueDate: DateTime.now().add(const Duration(days: 30)),
        isPaid: false,
      ),
      InstallmentPlan(
        installmentNumber: 2,
        amount: 500.0,
        dueDate: DateTime.now().add(const Duration(days: 60)),
        isPaid: false,
      ),
    ],
  );

  setUp(() {
    mockRepo = MockDebtRepository();
    mockSyncService = MockOfflineSyncService();
    when(mockRepo.getDebts()).thenAnswer((_) async => [testDebt]);
    debtNotifier = DebtNotifier(repository: mockRepo, syncService: mockSyncService);
  });

  group('DebtNotifier Unit Tests', () {
    test('initial state loads debt list correctly', () async {
      await Future<void>.delayed(Duration.zero);
      expect(debtNotifier.state.debts.length, equals(1));
      expect(debtNotifier.state.totalDebtAmount, equals(1000.0));
      expect(debtNotifier.state.totalRemainingAmount, equals(1000.0));
    });

    test('createDebt validates debtor name and amount', () async {
      await Future<void>.delayed(Duration.zero);
      final emptyNameResult = await debtNotifier.createDebt(
        debtorName: '  ',
        amount: 500.0,
        installmentCount: 2,
      );
      expect(emptyNameResult, isFalse);
      expect(debtNotifier.state.errorMessage, contains('boş olamaz'));

      final invalidAmountResult = await debtNotifier.createDebt(
        debtorName: 'Mehmet',
        amount: -50,
        installmentCount: 1,
      );
      expect(invalidAmountResult, isFalse);
      expect(debtNotifier.state.errorMessage, contains('0\'dan büyük'));
    });

    test('createDebt invokes repository and reloads debts', () async {
      await Future<void>.delayed(Duration.zero);
      when(mockRepo.createDebt('Mehmet Demir', 600.0, 2)).thenAnswer(
        (_) async => testDebt.copyWith(id: 'd2', debtorName: 'Mehmet Demir', totalAmount: 600.0),
      );

      final result = await debtNotifier.createDebt(
        debtorName: 'Mehmet Demir',
        amount: 600.0,
        installmentCount: 2,
      );

      expect(result, isTrue);
      verify(mockRepo.createDebt('Mehmet Demir', 600.0, 2)).called(1);
    });

    test('payInstallment calls repository payment logic', () async {
      await Future<void>.delayed(Duration.zero);
      when(mockRepo.payInstallment('d1', 1)).thenAnswer(
        (_) async => testDebt.copyWith(remainingAmount: 500.0),
      );

      final result = await debtNotifier.payInstallment('d1', 1);

      expect(result, isTrue);
      verify(mockRepo.payInstallment('d1', 1)).called(1);
    });

    test('filter switching filters debt items correctly', () async {
      await Future<void>.delayed(Duration.zero);
      final paidDebt = testDebt.copyWith(id: 'd_paid', status: DebtStatus.paid, remainingAmount: 0);
      debtNotifier.state = debtNotifier.state.copyWith(debts: [testDebt, paidDebt]);

      debtNotifier.setFilter('active');
      expect(debtNotifier.state.filteredDebts.length, equals(1));
      expect(debtNotifier.state.filteredDebts.first.id, equals('d1'));

      debtNotifier.setFilter('paid');
      expect(debtNotifier.state.filteredDebts.length, equals(1));
      expect(debtNotifier.state.filteredDebts.first.id, equals('d_paid'));

      debtNotifier.setFilter('all');
      expect(debtNotifier.state.filteredDebts.length, equals(2));
    });
  });
}
