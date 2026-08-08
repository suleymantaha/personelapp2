import 'dart:async';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../domain/debt_models.dart';

abstract class DebtRepository {
  Future<List<DebtItem>> getDebts();
  Future<DebtItem> createDebt(String debtorName, double amount, int installmentCount);
  Future<DebtItem> payInstallment(String debtId, int installmentNumber);
  Future<DebtItem> payAmount(String debtId, double amount);
  Future<void> saveLocalDebts(List<DebtItem> debts);
  Future<List<DebtItem>> loadLocalDebts();
}

class DebtRepositoryImpl implements DebtRepository {
  final ApiClient apiClient;
  final LocalStorageService localStorageService;

  DebtRepositoryImpl({
    required this.apiClient,
    required this.localStorageService,
  });

  static const String _debtStorageKey = 'user_debt_records';

  @override
  Future<List<DebtItem>> getDebts() async {
    final local = await loadLocalDebts();
    if (local.isNotEmpty) return local;

    final initial = [
      DebtItem(
        id: 'd1',
        debtorName: 'Ahmet Yılmaz',
        totalAmount: 1200.0,
        remainingAmount: 800.0,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        status: DebtStatus.active,
        installments: [
          InstallmentPlan(
            installmentNumber: 1,
            amount: 400.0,
            dueDate: DateTime.now().subtract(const Duration(days: 5)),
            isPaid: true,
            paidDate: DateTime.now().subtract(const Duration(days: 5)),
          ),
          InstallmentPlan(
            installmentNumber: 2,
            amount: 400.0,
            dueDate: DateTime.now().add(const Duration(days: 25)),
            isPaid: false,
          ),
          InstallmentPlan(
            installmentNumber: 3,
            amount: 400.0,
            dueDate: DateTime.now().add(const Duration(days: 55)),
            isPaid: false,
          ),
        ],
      ),
      DebtItem(
        id: 'd2',
        debtorName: 'Mehmet Demir',
        totalAmount: 500.0,
        remainingAmount: 500.0,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: DebtStatus.active,
        installments: [
          InstallmentPlan(
            installmentNumber: 1,
            amount: 500.0,
            dueDate: DateTime.now().add(const Duration(days: 10)),
            isPaid: false,
          ),
        ],
      ),
    ];
    await saveLocalDebts(initial);
    return initial;
  }

  @override
  Future<DebtItem> createDebt(String debtorName, double amount, int installmentCount) async {
    if (amount <= 0) throw Exception('Tutar 0 veya negatif olamaz.');
    if (installmentCount <= 0) throw Exception('Taksit sayısı en az 1 olmalıdır.');

    final eachAmount = amount / installmentCount;
    final installments = List.generate(
      installmentCount,
      (index) => InstallmentPlan(
        installmentNumber: index + 1,
        amount: eachAmount,
        dueDate: DateTime.now().add(Duration(days: (index + 1) * 30)),
        isPaid: false,
      ),
    );

    final isConnected = await apiClient.isNetworkConnected();
    final newDebt = DebtItem(
      id: 'd_${DateTime.now().millisecondsSinceEpoch}',
      debtorName: debtorName,
      totalAmount: amount,
      remainingAmount: amount,
      createdAt: DateTime.now(),
      status: DebtStatus.active,
      installments: installments,
      isSynced: isConnected,
    );

    final current = await loadLocalDebts();
    final updated = [...current, newDebt];
    await saveLocalDebts(updated);
    return newDebt;
  }

  @override
  Future<DebtItem> payInstallment(String debtId, int installmentNumber) async {
    final current = await loadLocalDebts();
    final index = current.indexWhere((d) => d.id == debtId);
    if (index < 0) throw Exception('Borç kaydı bulunamadı.');

    final debt = current[index];
    final instIndex = debt.installments.indexWhere((i) => i.installmentNumber == installmentNumber);
    if (instIndex < 0) throw Exception('Taksit bulunamadı.');

    final targetInst = debt.installments[instIndex];
    if (targetInst.isPaid) throw Exception('Bu taksit zaten ödenmiş.');

    final updatedInsts = List<InstallmentPlan>.from(debt.installments);
    updatedInsts[instIndex] = targetInst.copyWith(
      isPaid: true,
      paidDate: DateTime.now(),
    );

    final newRemaining = debt.remainingAmount - targetInst.amount;
    final isFullyPaid = newRemaining <= 0.01;

    final updatedDebt = debt.copyWith(
      installments: updatedInsts,
      remainingAmount: isFullyPaid ? 0.0 : newRemaining,
      status: isFullyPaid ? DebtStatus.paid : debt.status,
    );

    current[index] = updatedDebt;
    await saveLocalDebts(current);
    return updatedDebt;
  }

  @override
  Future<DebtItem> payAmount(String debtId, double amount) async {
    if (amount <= 0) throw Exception('Ödeme tutarı 0\'dan büyük olmalıdır.');
    final current = await loadLocalDebts();
    final index = current.indexWhere((d) => d.id == debtId);
    if (index < 0) throw Exception('Borç kaydı bulunamadı.');

    final debt = current[index];
    if (amount > debt.remainingAmount) {
      throw Exception('Ödeme tutarı kalan borçtan fazla olamaz.');
    }

    final newRemaining = debt.remainingAmount - amount;
    final isFullyPaid = newRemaining <= 0.01;

    final updatedDebt = debt.copyWith(
      remainingAmount: isFullyPaid ? 0.0 : newRemaining,
      status: isFullyPaid ? DebtStatus.paid : debt.status,
    );

    current[index] = updatedDebt;
    await saveLocalDebts(current);
    return updatedDebt;
  }

  @override
  Future<void> saveLocalDebts(List<DebtItem> debts) async {
    final listJson = debts.map((e) => e.toJson()).toList();
    await localStorageService.saveList(_debtStorageKey, listJson);
  }

  @override
  Future<List<DebtItem>> loadLocalDebts() async {
    try {
      final list = await localStorageService.getList(_debtStorageKey);
      return list.map((e) => DebtItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
