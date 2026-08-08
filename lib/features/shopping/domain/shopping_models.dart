class ShoppingProduct {
  final String id;
  final String title;
  final double price;
  final int stock;
  final String category;
  final String imageUrl;

  const ShoppingProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.stock,
    required this.category,
    this.imageUrl = '',
  });

  ShoppingProduct copyWith({
    String? id,
    String? title,
    double? price,
    int? stock,
    String? category,
    String? imageUrl,
  }) {
    return ShoppingProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'stock': stock,
        'category': category,
        'imageUrl': imageUrl,
      };

  factory ShoppingProduct.fromJson(Map<String, dynamic> json) => ShoppingProduct(
        id: json['id'] as String,
        title: json['title'] as String,
        price: (json['price'] as num).toDouble(),
        stock: json['stock'] as int,
        category: json['category'] as String? ?? 'General',
        imageUrl: json['imageUrl'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingProduct &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          price == other.price &&
          stock == other.stock &&
          category == other.category;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ price.hashCode ^ stock.hashCode ^ category.hashCode;
}

class CartItem {
  final ShoppingProduct product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;

  CartItem copyWith({
    ShoppingProduct? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: ShoppingProduct.fromJson(json['product'] as Map<String, dynamic>),
        quantity: json['quantity'] as int,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          quantity == other.quantity;

  @override
  int get hashCode => product.hashCode ^ quantity.hashCode;
}
