import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/shopping_repository.dart';
import '../../domain/shopping_models.dart';

class CartState {
  final List<ShoppingProduct> products;
  final List<CartItem> items;
  final bool isLoading;
  final String? errorMessage;
  final double discountPercent;

  const CartState({
    this.products = const [],
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.discountPercent = 0.0,
  });

  double get rawTotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get discountAmount => rawTotal * (discountPercent / 100.0);
  double get netTotal => rawTotal - discountAmount;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<ShoppingProduct>? products,
    List<CartItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    double? discountPercent,
  }) {
    return CartState(
      products: products ?? this.products,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final ShoppingRepository repository;

  CartNotifier(this.repository) : super(const CartState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    try {
      final products = await repository.getProducts();
      final savedCart = await repository.loadCart();
      state = state.copyWith(
        products: products,
        items: savedCart,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void addToCart(ShoppingProduct product, {int quantity = 1}) {
    if (quantity <= 0) return;
    if (product.stock <= 0) {
      state = state.copyWith(errorMessage: 'Stok yetersiz!');
      return;
    }

    final index = state.items.indexWhere((item) => item.product.id == product.id);
    List<CartItem> newItems = List.from(state.items);

    if (index >= 0) {
      final existing = newItems[index];
      final newQuantity = existing.quantity + quantity;
      if (newQuantity > product.stock) {
        state = state.copyWith(errorMessage: 'Stok miktarını aşamazsınız.');
        return;
      }
      newItems[index] = existing.copyWith(quantity: newQuantity);
    } else {
      if (quantity > product.stock) {
        state = state.copyWith(errorMessage: 'Stok miktarını aşamazsınız.');
        return;
      }
      newItems.add(CartItem(product: product, quantity: quantity));
    }

    state = state.copyWith(items: newItems, clearError: true);
    repository.saveCart(newItems);
  }

  void removeFromCart(String productId) {
    final newItems = state.items.where((item) => item.product.id != productId).toList();
    state = state.copyWith(items: newItems, clearError: true);
    repository.saveCart(newItems);
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = state.items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = state.items[index];
      if (newQuantity > item.product.stock) {
        state = state.copyWith(errorMessage: 'Stok miktarını aşamazsınız.');
        return;
      }
      List<CartItem> newItems = List.from(state.items);
      newItems[index] = item.copyWith(quantity: newQuantity);
      state = state.copyWith(items: newItems, clearError: true);
      repository.saveCart(newItems);
    }
  }

  void applyDiscount(double percent) {
    if (percent < 0 || percent > 100) return;
    state = state.copyWith(discountPercent: percent);
  }

  void clearCart() {
    state = state.copyWith(items: [], clearError: true);
    repository.saveCart([]);
  }

  Future<bool> checkout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.checkout(state.items);
      state = state.copyWith(items: [], isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}
