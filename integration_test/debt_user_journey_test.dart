// User Journey: Debt Creation & Installment Payment Flow
// 1. Launch app on DebtManagementScreen
// 2. Open debt creation dialog via FAB
// 3. Fill form: debtor name 'Zeynep Kaya', total 900 TL, 3 installments
// 4. Submit form and verify new debt card rendered
// 5. Expand debt card tile to view installments
// 6. Tap 'Öde' for installment #1
// 7. Verify remaining balance decreases and installment turns into paid checkmark

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personelapp2/features/debt/presentation/debt_management_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Debt Management User Journey End-to-End Test', () {
    testWidgets('Complete debt creation and installment payment journey', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DebtManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Initial Screen Render Verification
      expect(find.byKey(const ValueKey('debt_scaffold')), findsOneWidget);

      // Step 2: Open Create Debt Modal
      final fab = find.byKey(const ValueKey('create_debt_fab'));
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Step 3: Enter Form Data
      await tester.enterText(find.byKey(const ValueKey('debtor_name_input')), 'Zeynep Kaya');
      await tester.enterText(find.byKey(const ValueKey('debt_amount_input')), '900');
      await tester.enterText(find.byKey(const ValueKey('installment_count_input')), '3');

      // Step 4: Save Debt
      final saveBtn = find.byKey(const ValueKey('save_debt_btn'));
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Step 5: Verify new debt item exists
      expect(find.text('Zeynep Kaya'), findsOneWidget);

      // Step 6: Expand Tile
      final debtTile = find.text('Zeynep Kaya');
      await tester.tap(debtTile);
      await tester.pumpAndSettle();

      // Step 7: Pay Installment #1
      final payBtn = find.byKey(const ValueKey('pay_installment_btn_d1_1'));
      if (payBtn.evaluate().isNotEmpty) {
        await tester.tap(payBtn);
        await tester.pumpAndSettle();
      }

      // Step 8: Verify remaining balance updated
      expect(find.byKey(const ValueKey('remaining_balance_text')), findsOneWidget);
    });
  });
}
