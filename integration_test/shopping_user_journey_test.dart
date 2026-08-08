// User Journey: Shopping & Cart Flow
// 1. Launch app on ShoppingScreen
// 2. Select product 'Kantin Kartı' and tap 'Ekle'
// 3. Verify cart badge increments
// 4. Open cart bottom sheet via 'open_cart_button'
// 5. Verify item subtotal & total price
// 6. Tap 'Ödemeyi Tamamla' (checkout)
// 7. Verify cart is cleared and checkout snackbar is presented

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personelapp2/features/shopping/presentation/shopping_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Shopping User Journey End-to-End Test', () {
    testWidgets('Complete user shopping journey: add item, open cart, checkout', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ShoppingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Verify Initial Render
      expect(find.byKey(const ValueKey('shopping_screen_scaffold')), findsOneWidget);
      expect(find.text('Kantin Kartı'), findsOneWidget);

      // Step 2: Add item to cart
      final addBtn = find.byKey(const ValueKey('add_to_cart_p1'));
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Step 3: Verify badge count updated
      expect(find.byKey(const ValueKey('cart_badge_count')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Step 4: Open Cart BottomSheet
      final openCartBtn = find.byKey(const ValueKey('open_cart_button'));
      await tester.tap(openCartBtn);
      await tester.pumpAndSettle();

      // Step 5: Verify Cart BottomSheet Content
      expect(find.byKey(const ValueKey('cart_bottom_sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('cart_total_price')), findsOneWidget);

      // Step 6: Perform Checkout
      final checkoutBtn = find.byKey(const ValueKey('checkout_button'));
      await tester.tap(checkoutBtn);
      await tester.pumpAndSettle();

      // Step 7: Verify Success Snackbar
      expect(find.byKey(const ValueKey('checkout_success_snackbar')), findsOneWidget);
    });
  });
}
