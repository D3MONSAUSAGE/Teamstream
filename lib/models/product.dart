class Product {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double price;
  int quantity; // Make this field mutable
  final int minQuantity;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.quantity,
    required this.minQuantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      unit: json['unit'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      minQuantity: json['min_quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'unit': unit,
      'price': price,
      'quantity': quantity,
      'min_quantity': minQuantity,
    };
  }
}
