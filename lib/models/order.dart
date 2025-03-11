class Order {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final DateTime orderDate;

  Order({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.orderDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      productId: json['productId'],
      productName: json['productName'],
      quantity: json['quantity'],
      orderDate: DateTime.parse(json['orderDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'orderDate': orderDate.toIso8601String(),
    };
  }
}
