import 'dart:async';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../domain/shopping_models.dart';

abstract class ShoppingRepository {
  Future<List<ShoppingProduct>> getProducts();
  Future<List<CartItem>> loadCart();
  Future<void> saveCart(List<CartItem> cart);
  Future<bool> checkout(List<CartItem> cart);
}

class ShoppingRepositoryImpl implements ShoppingRepository {
  final ApiClient apiClient;
  final LocalStorageService localStorageService;

  ShoppingRepositoryImpl({
    required this.apiClient,
    required this.localStorageService,
  });

  static const String _cartStorageKey = 'user_shopping_cart';

  @override
  Future<List<ShoppingProduct>> getProducts() async {
    return const [
      ShoppingProduct(id: 'p1', title: 'Kantin Kartı', price: 50.0, stock: 100, category: 'Kart'),
      ShoppingProduct(id: 'p2', title: 'Üniforma Rozeti', price: 25.0, stock: 50, category: 'Aksesuar'),
      ShoppingProduct(id: 'p3', title: 'Defter Seti', price: 15.5, stock: 200, category: 'Kırtasiye'),
      ShoppingProduct(id: 'p4', title: 'Termos 1L', price: 120.0, stock: 30, category: 'Ekipman'),
    ];
  }

  @override
  Future<List<CartItem>> loadCart() async {
    try {
      final list = await localStorageService.getList(_cartStorageKey);
      return list.map((json) => CartItem.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveCart(List<CartItem> cart) async {
    final listJson = cart.map((item) => item.toJson()).toList();
    await localStorageService.saveList(_cartStorageKey, listJson);
  }

  @override
  Future<bool> checkout(List<CartItem> cart) async {
    if (cart.isEmpty) {
      throw Exception('Sepet boş, ödeme yapılamaz.');
    }
    final isConnected = await apiClient.isNetworkConnected();
    if (!isConnected) {
      throw Exception('İnternet bağlantısı yok, sipariş gönderilemedi.');
    }
    await apiClient.post('/shopping/checkout', body: {
      'items': cart.map((e) => e.toJson()).toList(),
      'total': cart.fold<double>(0, (sum, item) => sum + item.subtotal),
    });
    await localStorageService.remove(_cartStorageKey);
    return true;
  }
}
