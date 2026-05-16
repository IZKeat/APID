class CartItem {
  final String productId;
  final String name;
  final double price;
  int qty;
  final List<String> modifiers; // e.g., ["Less Sugar", "No Ice"]
  final String? notes; // e.g., "Allergy: Peanuts"

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.qty = 1,
    this.modifiers = const [],
    this.notes,
  });

  double get total => price * qty;

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'qty': qty,
      'modifiers': modifiers,
      if (notes != null) 'notes': notes,
    };
  }

  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? qty,
    List<String>? modifiers,
    String? notes,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      qty: qty ?? this.qty,
      modifiers: modifiers ?? this.modifiers,
      notes: notes ?? this.notes,
    );
  }
}
