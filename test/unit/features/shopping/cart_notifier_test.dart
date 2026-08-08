import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:personelapp2/features/shopping/domain/shopping_models.dart';
import 'package:personelapp2/features/shopping/presentation/providers/cart_notifier.dart';

import '../../../mocks/mock_annotations.mocks.dart';

void main() {
  late MockShoppingRepository mockRepo;
  late CartNotifier cartNotifier;

  const testProduct1 = ShoppingProduct(
    id: 'p1',
    title: 'Test Urun 1',
    price: 100.0,
    stock: 10,
    category: 'Genel',
  );

  const testProduct2 = ShoppingProduct(
    id: 'p2',
    title: 'Test Urun 2',
    price: 50.0,
    stock: 5,
    category: 'Genel',
  );

  setUp(() {
    mockRepo = MockShoppingRepository();
    when(mockRepo.getProducts()).thenAnswer((_) async => [testProduct1, testProduct2]);
    when(mockRepo.loadCart()).thenAnswer((_) async => []);
    when(mockRepo.saveCart(any)).thenAnswer((_) async {});
    cartNotifier = CartNotifier(mockRepo);
  });

  group('CartNotifier Unit Tests', () {
    test('initial state loads products and empty cart', () async {
      await Future<void>.delayed(Duration.zero);
      expect(cartNotifier.state.products.length, equals(2));
      expect(cartNotifier.state.items, isEmpty);
      expect(cartNotifier.state.itemCount, equals(0));
      expect(cartNotifier.state.rawTotal, equals(0.0));
    });

    test('addToCart adds product to cart correctly', () async {
      await Future<void>.delayed(Duration.zero);
      cartNotifier.addToCart(testProduct1, quantity: 2);

      expect(cartNotifier.state.items.length, equals(1));
      expect(cartNotifier.state.items.first.quantity, equals(2));
      expect(cartNotifier.state.rawTotal, equals(200.0));
      verify(mockRepo.saveCart(any)).called(1);
    });

    test('addToCart handles stock limits gracefully', () async {
      await Future<void>.delayed(Duration.zero);
      final outOfStockProduct = testProduct1.copyWith(stock: 0);

      cartNotifier.addToCart(outOfStockProduct);

      expect(cartNotifier.state.items, isEmpty);
      expect(cartNotifier.state.errorMessage, contains('Stok yetersiz'));
    });

    test('updateQuantity adjusts cart item quantity', () async {
      await Future<void>.delayed(Duration.zero);
      cartNotifier.addToCart(testProduct1, quantity: 1);
      cartNotifier.updateQuantity('p1', 5);

      expect(cartNotifier.state.items.first.quantity, equals(5));
      expect(cartNotifier.state.rawTotal, equals(500.0));
    });

    test('updateQuantity removes item if quantity set to 0', () async {
      await Future<void>.delayed(Duration.zero);
      cartNotifier.addToCart(testProduct1, quantity: 2);
      cartNotifier.updateQuantity('p1', 0);

      expect(cartNotifier.state.items, isEmpty);
    });

    test('removeFromCart deletes specified product', () async {
      await Future<void>.delayed(Duration.zero);
      cartNotifier.addToCart(testProduct1);
      cartNotifier.addToCart(testProduct2);
      expect(cartNotifier.state.items.length, equals(2));

      cartNotifier.removeFromCart('p1');
      expect(cartNotifier.state.items.length, equals(1));
      expect(cartNotifier.state.items.first.product.id, equals('p2'));
    });

    test('applyDiscount calculates net total correctly', () async {
      await Future<void>.delayed(Duration.zero);
      cartNotifier.addToCart(testProduct1, quantity: 2);
      cartNotifier.applyDiscount(10.0);

      expect(cartNotifier.state.discountAmount, equals(20.0));
      expect(cartNotifier.state.netTotal, equals(180.0));
    });

    test('checkout clears cart on success', () async {
      await Future<void>.delayed(Duration.zero);
      when(mockRepo.checkout(any)).thenAnswer((_) async => true);

      cartNotifier.addToCart(testProduct1);
      final success = await cartNotifier.checkout();

      expect(success, isTrue);
      expect(cartNotifier.state.items, isEmpty);
      expect(cartNotifier.state.errorMessage, isNull);
    });

    test('checkout handles error and sets errorMessage', () async {
      await Future<void>.delayed(Duration.zero);
      when(mockRepo.checkout(any)).thenThrow(Exception('Sunucu hatasi'));

      cartNotifier.addToCart(testProduct1);
      final success = await cartNotifier.checkout();

      expect(success, isFalse);
      expect(cartNotifier.state.errorMessage, contains('Sunucu hatasi'));
    });
  });
}
