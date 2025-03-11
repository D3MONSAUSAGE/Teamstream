import 'package:teamstream/models/product.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';

class InventoryService {
  static const String _collection = 'products';
  static const String _historyCollection = 'history';

  /// Fetch all products
  static Future<List<Product>> fetchProducts() async {
    final data = await BaseService.fetchAll(_collection);
    return data.map((item) => Product.fromJson(item)).toList();
  }

  /// Fetch a single product by ID
  static Future<Product?> fetchProductById(String id) async {
    final data = await BaseService.fetchOne(_collection, id);
    return data != null ? Product.fromJson(data) : null;
  }

  /// Add a new product
  static Future<String?> addProduct(Product product) async {
    return await BaseService.create(_collection, product.toJson());
  }

  /// Update an existing product
  static Future<bool> updateProduct(Product product) async {
    return await BaseService.update(
      _collection,
      product.id,
      product.toJson(),
    );
  }

  /// Delete a product by ID
  static Future<bool> deleteProduct(String id) async {
    return await BaseService.delete(_collection, id);
  }

  /// Save inventory snapshot
  static Future<void> saveInventorySnapshot(Product product) async {
    final snapshot = {
      'productId': product.id,
      'productName': product.name,
      'quantity': product.quantity,
      'date': DateTime.now().toIso8601String(),
    };
    await BaseService.create(_historyCollection, snapshot);
  }

  /// Fetch historical data for a product
  static Future<List<Map<String, dynamic>>> fetchInventoryHistory(
      String productId) async {
    final data = await BaseService.fetchByField(
        _historyCollection, 'productId', productId);
    return data;
  }

  /// Deduct inventory for a product
  static Future<bool> deductInventory(String productId, int quantity) async {
    final product = await fetchProductById(productId);
    if (product != null && product.quantity >= quantity) {
      product.quantity -= quantity;
      await updateProduct(product);
      await saveInventorySnapshot(product);
      return true;
    }
    return false;
  }
}
