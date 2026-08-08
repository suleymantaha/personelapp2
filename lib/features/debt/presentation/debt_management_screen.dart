import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../data/debt_repository.dart';
import '../services/offline_sync_service.dart';
import 'providers/debt_notifier.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(
    apiClient: HttpApiClient(),
    localStorageService: InMemoryLocalStorageService(),
  );
});

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final repo = ref.watch(debtRepositoryProvider);
  return OfflineSyncService(
    apiClient: HttpApiClient(),
    debtRepository: repo,
  );
});

final debtNotifierProvider = StateNotifierProvider<DebtNotifier, DebtState>((ref) {
  final repo = ref.watch(debtRepositoryProvider);
  final syncService = ref.watch(offlineSyncServiceProvider);
  return DebtNotifier(repository: repo, syncService: syncService);
});

class DebtManagementScreen extends ConsumerWidget {
  const DebtManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtState = ref.watch(debtNotifierProvider);
    final notifier = ref.read(debtNotifierProvider.notifier);

    return Scaffold(
      key: const ValueKey('debt_scaffold'),
      appBar: AppBar(
        title: const Text('Borç Yönetimi & Taksitlendirme'),
        actions: [
          IconButton(
            key: const ValueKey('sync_button'),
            icon: debtState.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync),
            onPressed: () => notifier.triggerSync(),
          ),
        ],
      ),
      body: debtState.isLoading
          ? const Center(
              key: ValueKey('debt_loading_indicator'),
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                if (debtState.errorMessage != null)
                  Container(
                    key: const ValueKey('debt_error_banner'),
                    color: Colors.red.shade100,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      debtState.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                const Text('Toplam Alacak', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  '₺${debtState.totalDebtAmount.toStringAsFixed(2)}',
                                  key: const ValueKey('total_debt_text'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                const Text('Kalan Bakiye', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  '₺${debtState.totalRemainingAmount.toStringAsFixed(2)}',
                                  key: const ValueKey('remaining_balance_text'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    key: const ValueKey('debt_list_view'),
                    itemCount: debtState.filteredDebts.length,
                    itemBuilder: (context, index) {
                      final debt = debtState.filteredDebts[index];
                      return Card(
                        key: ValueKey('debt_card_${debt.id}'),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ExpansionTile(
                          key: ValueKey('debt_tile_${debt.id}'),
                          title: Text(debt.debtorName, key: ValueKey('debtor_name_${debt.id}')),
                          subtitle: Text('Kalan: ₺${debt.remainingAmount.toStringAsFixed(2)} / Toplam: ₺${debt.totalAmount}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: debt.status.name == 'paid' ? Colors.green.shade100 : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              debt.status.name.toUpperCase(),
                              key: ValueKey('debt_status_${debt.id}'),
                              style: TextStyle(
                                color: debt.status.name == 'paid' ? Colors.green.shade900 : Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          children: [
                            ...debt.installments.map(
                              (inst) => ListTile(
                                key: ValueKey('installment_row_${debt.id}_${inst.installmentNumber}'),
                                title: Text('Taksit #${inst.installmentNumber}: ₺${inst.amount.toStringAsFixed(2)}'),
                                subtitle: Text('Son Ödeme: ${inst.dueDate.day}/${inst.dueDate.month}/${inst.dueDate.year}'),
                                trailing: inst.isPaid
                                    ? const Icon(Icons.check_circle, color: Colors.green, key: ValueKey('paid_icon'))
                                    : ElevatedButton(
                                        key: ValueKey('pay_installment_btn_${debt.id}_${inst.installmentNumber}'),
                                        onPressed: () => notifier.payInstallment(debt.id, inst.installmentNumber),
                                        child: const Text('Öde'),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('create_debt_fab'),
        onPressed: () => _showCreateDebtDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDebtDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final installmentController = TextEditingController(text: '1');

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: const ValueKey('create_debt_dialog'),
          title: const Text('Yeni Borç Kaydı Oluştur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('debtor_name_input'),
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Borçlu Adı Soyadı'),
              ),
              TextField(
                key: const ValueKey('debt_amount_input'),
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Toplam Borç Tutarı (₺)'),
              ),
              TextField(
                key: const ValueKey('installment_count_input'),
                controller: installmentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Taksit Sayısı'),
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const ValueKey('cancel_debt_btn'),
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              key: const ValueKey('save_debt_btn'),
              onPressed: () async {
                final name = nameController.text;
                final amount = double.tryParse(amountController.text) ?? 0;
                final count = int.tryParse(installmentController.text) ?? 1;

                final notifier = ref.read(debtNotifierProvider.notifier);
                final success = await notifier.createDebt(
                  debtorName: name,
                  amount: amount,
                  installmentCount: count,
                );

                if (success && context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}
