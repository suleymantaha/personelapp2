import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/shopping_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import 'providers/cart_notifier.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepositoryImpl(
    apiClient: HttpApiClient(),
    localStorageService: InMemoryLocalStorageService(),
  );
});

final cartNotifierProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final repo = ref.watch(shoppingRepositoryProvider);
  return CartNotifier(repo);
});

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);
    final notifier = ref.read(cartNotifierProvider.notifier);

    return Scaffold(
      key: const ValueKey('shopping_screen_scaffold'),
      appBar: AppBar(
        title: const Text('Alışveriş & Kantin Modülü'),
        actions: [
          Stack(
            children: [
              IconButton(
                key: const ValueKey('open_cart_button'),
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  _showCartBottomSheet(context, ref);
                },
              ),
              if (cartState.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cartState.itemCount}',
                        key: const ValueKey('cart_badge_count'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: cartState.isLoading
          ? const Center(
              key: ValueKey('shopping_loading_indicator'),
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                if (cartState.errorMessage != null)
                  Container(
                    key: const ValueKey('shopping_error_banner'),
                    color: Colors.red.shade100,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cartState.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    key: const ValueKey('product_list_view'),
                    itemCount: cartState.products.length,
                    itemBuilder: (context, index) {
                      final product = cartState.products[index];
                      return ListTile(
                        key: ValueKey('product_tile_${product.id}'),
                        title: Text(product.title, key: ValueKey('product_title_${product.id}')),
                        subtitle: Text('₺${product.price.toStringAsFixed(2)} | Stok: ${product.stock}'),
                        trailing: ElevatedButton(
                          key: ValueKey('add_to_cart_${product.id}'),
                          onPressed: () => notifier.addToCart(product),
                          child: const Text('Ekle'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showCartBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final cartState = ref.watch(cartNotifierProvider);
            final notifier = ref.read(cartNotifierProvider.notifier);

            return Container(
              key: const ValueKey('cart_bottom_sheet'),
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sepetim',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        key: const ValueKey('close_cart_button'),
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (cartState.items.isEmpty)
                    const Expanded(
                      child: Center(
                        key: ValueKey('empty_cart_text'),
                        child: Text('Sepetiniz boş'),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: ListView.builder(
                        key: const ValueKey('cart_items_list'),
                        itemCount: cartState.items.length,
                        itemBuilder: (context, index) {
                          final item = cartState.items[index];
                          return ListTile(
                            key: ValueKey('cart_item_${item.product.id}'),
                            title: Text(item.product.title),
                            subtitle: Text('₺${item.product.price} x ${item.quantity} = ₺${item.subtotal.toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  key: ValueKey('decrement_item_${item.product.id}'),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => notifier.updateQuantity(item.product.id, item.quantity - 1),
                                ),
                                Text('${item.quantity}', key: ValueKey('item_qty_${item.product.id}')),
                                IconButton(
                                  key: ValueKey('increment_item_${item.product.id}'),
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => notifier.updateQuantity(item.product.id, item.quantity + 1),
                                ),
                                IconButton(
                                  key: ValueKey('remove_item_${item.product.id}'),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => notifier.removeFromCart(item.product.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Toplam Tutar:'),
                        Text(
                          '₺${cartState.netTotal.toStringAsFixed(2)}',
                          key: const ValueKey('cart_total_price'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const ValueKey('checkout_button'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () async {
                          final success = await notifier.checkout();
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                key: ValueKey('checkout_success_snackbar'),
                                content: Text('Sipariş başarıyla tamamlandı!'),
                              ),
                            );
                          }
                        },
                        child: const Text('Ödemeyi Tamamla'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
