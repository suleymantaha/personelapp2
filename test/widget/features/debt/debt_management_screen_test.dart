import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:personelapp2/features/debt/domain/debt_models.dart';
import 'package:personelapp2/features/debt/presentation/debt_management_screen.dart';

import '../../../mocks/mock_annotations.mocks.dart';

void main() {
  late MockDebtRepository mockRepo;
  late MockOfflineSyncService mockSyncService;

  final testDebts = [
    DebtItem(
      id: 'd1',
      debtorName: 'Ahmet Yılmaz',
      totalAmount: 1200.0,
      remainingAmount: 800.0,
      createdAt: DateTime.now(),
      status: DebtStatus.active,
      installments: [
        InstallmentPlan(
          installmentNumber: 1,
          amount: 400.0,
          dueDate: DateTime.now().add(const Duration(days: 30)),
          isPaid: false,
        ),
      ],
    ),
  ];

  setUp(() {
    mockRepo = MockDebtRepository();
    mockSyncService = MockOfflineSyncService();
    when(mockRepo.getDebts()).thenAnswer((_) async => testDebts);
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        debtRepositoryProvider.overrideWithValue(mockRepo),
        offlineSyncServiceProvider.overrideWithValue(mockSyncService),
      ],
      child: const MaterialApp(
        home: DebtManagementScreen(),
      ),
    );
  }

  group('DebtManagementScreen Widget Tests', () {
    testWidgets('renders debt list and totals correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('debt_scaffold')), findsOneWidget);
      expect(find.byKey(const ValueKey('total_debt_text')), findsOneWidget);
      expect(find.byKey(const ValueKey('remaining_balance_text')), findsOneWidget);
      expect(find.text('Ahmet Yılmaz'), findsOneWidget);
      expect(find.byKey(const ValueKey('create_debt_fab')), findsOneWidget);
    });

    testWidgets('tapping FAB opens creation dialog', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('create_debt_fab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('create_debt_dialog')), findsOneWidget);
      expect(find.byKey(const ValueKey('debtor_name_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('save_debt_btn')), findsOneWidget);
    });
  });
}
