import 'package:teamstream/models/order.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';

class OrderService {
  static const String _collection = 'orders';

  /// Fetch all orders
  static Future<List<Order>> fetchOrders() async {
    final data = await BaseService.fetchAll(_collection);
    return data.map((item) => Order.fromJson(item)).toList();
  }

  /// Create a new order
  static Future<String?> createOrder(Order order) async {
    return await BaseService.create(_collection, order.toJson());
  }

  /// Delete an order by ID
  static Future<bool> deleteOrder(String id) async {
    return await BaseService.delete(_collection, id);
  }
}
