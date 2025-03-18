import 'package:flutter/material.dart';
import 'package:teamstream/models/product.dart';
import 'package:teamstream/services/pocketbase/inventory_service.dart';
import 'package:teamstream/pages/inventory/add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final items = await InventoryService.fetchProducts();
    setState(() {
      products = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text(
                '${product.quantity} ${product.unit} (Min: ${product.minQuantity} ${product.unit})'),
            trailing: Text('\$${product.price.toStringAsFixed(2)}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          );
          _fetchProducts(); // Refresh the list after adding a product
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
