import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:personelapp2/features/shopping/domain/shopping_models.dart';
import 'package:personelapp2/features/shopping/presentation/shopping_screen.dart';

import '../../../mocks/mock_annotations.mocks.dart';

void main() {
  late MockShoppingRepository mockRepo;

  const testProducts = [
    ShoppingProduct(id: 'p1', title: 'Kantin Kartı', price: 50.0, stock: 10, category: 'Kart'),
    ShoppingProduct(id: 'p2', title: 'Üniforma Rozeti', price: 25.0, stock: 5, category: 'Aksesuar'),
  ];

  setUp(() {
    mockRepo = MockShoppingRepository();
    when(mockRepo.getProducts()).thenAnswer((_) async => testProducts);
    when(mockRepo.loadCart()).thenAnswer((_) async => []);
    when(mockRepo.saveCart(any)).thenAnswer((_) async {});
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        shoppingRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: ShoppingScreen(),
      ),
    );
  }

  group('ShoppingScreen Widget Tests', () {
    testWidgets('renders products list correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('shopping_screen_scaffold')), findsOneWidget);
      expect(find.text('Kantin Kartı'), findsOneWidget);
      expect(find.text('Üniforma Rozeti'), findsOneWidget);
      expect(find.byKey(const ValueKey('add_to_cart_p1')), findsOneWidget);
    });

    testWidgets('tapping Ekle updates cart badge count', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cart_badge_count')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('add_to_cart_p1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cart_badge_count')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('opening cart bottom sheet displays item and total price', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Add product p1 to cart
      await tester.tap(find.byKey(const ValueKey('add_to_cart_p1')));
      await tester.pumpAndSettle();

      // Open cart
      await tester.tap(find.byKey(const ValueKey('open_cart_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cart_bottom_sheet')), findsOneWidget);
      expect(find.text('Sepetim'), findsOneWidget);
      expect(find.byKey(const ValueKey('cart_total_price')), findsOneWidget);
      expect(find.text('₺50.00'), findsWidgets);
      expect(find.byKey(const ValueKey('checkout_button')), findsOneWidget);
    });
  });
}
