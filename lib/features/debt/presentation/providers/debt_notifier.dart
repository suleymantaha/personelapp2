import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/debt_repository.dart';
import '../../domain/debt_models.dart';
import '../../services/offline_sync_service.dart';

class DebtState {
  final List<DebtItem> debts;
  final bool isLoading;
  final String? errorMessage;
  final String selectedFilter; // 'all', 'active', 'paid'
  final bool isSyncing;

  const DebtState({
    this.debts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilter = 'all',
    this.isSyncing = false,
  });

  List<DebtItem> get filteredDebts {
    if (selectedFilter == 'active') {
      return debts.where((d) => d.status == DebtStatus.active).toList();
    } else if (selectedFilter == 'paid') {
      return debts.where((d) => d.status == DebtStatus.paid).toList();
    }
    return debts;
  }

  double get totalDebtAmount => debts.fold(0.0, (sum, d) => sum + d.totalAmount);
  double get totalRemainingAmount => debts.fold(0.0, (sum, d) => sum + d.remainingAmount);

  DebtState copyWith({
    List<DebtItem>? debts,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? selectedFilter,
    bool? isSyncing,
  }) {
    return DebtState(
      debts: debts ?? this.debts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class DebtNotifier extends StateNotifier<DebtState> {
  final DebtRepository repository;
  final OfflineSyncService syncService;

  DebtNotifier({
    required this.repository,
    required this.syncService,
  }) : super(const DebtState()) {
    loadDebts();
  }

  Future<void> loadDebts() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await repository.getDebts();
      state = state.copyWith(debts: list, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<bool> createDebt({
    required String debtorName,
    required double amount,
    required int installmentCount,
  }) async {
    if (debtorName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Borçlu adı boş olamaz.');
      return false;
    }
    if (amount <= 0) {
      state = state.copyWith(errorMessage: 'Tutar 0\'dan büyük olmalıdır.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.createDebt(debtorName, amount, installmentCount);
      await loadDebts();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> payInstallment(String debtId, int installmentNumber) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.payInstallment(debtId, installmentNumber);
      await loadDebts();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> triggerSync() async {
    state = state.copyWith(isSyncing: true, clearError: true);
    final result = await syncService.synchronizePendingItems();
    await loadDebts();
    state = state.copyWith(
      isSyncing: false,
      errorMessage: result.isSuccess ? null : result.error,
    );
    return result.isSuccess;
  }
}
