import 'package:flutter/material.dart';
import 'package:teamstream/models/product.dart';
import 'package:teamstream/services/pocketbase/inventory_service.dart';
import 'package:teamstream/pages/inventory/add_product_screen.dart';
import 'package:teamstream/pages/inventory/dashboard_screen.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _sortBy = 'Name';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });
    final items = await InventoryService.fetchProducts();
    setState(() {
      products = items;
      filteredProducts = items;
      _isLoading = false;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      filteredProducts = products
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _sortProducts(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      switch (sortBy) {
        case 'Name':
          filteredProducts.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Category':
          filteredProducts.sort((a, b) => a.category.compareTo(b.category));
          break;
        case 'Quantity':
          filteredProducts.sort((a, b) => a.quantity.compareTo(b.quantity));
          break;
        case 'Price':
          filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
      }
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        filteredProducts = products;
      } else {
        filteredProducts =
            products.where((product) => product.category == category).toList();
      }
    });
  }

  Future<void> _updateProductQuantity(Product product, int newQuantity) async {
    if (newQuantity < 0) return;

    final updatedProduct = Product(
      id: product.id,
      name: product.name,
      category: product.category,
      unit: product.unit,
      price: product.price,
      quantity: newQuantity,
      minQuantity: product.minQuantity,
    );

    final success = await InventoryService.updateProduct(updatedProduct);
    if (success) {
      setState(() {
        product.quantity = newQuantity;
      });
      await InventoryService.saveInventorySnapshot(
          updatedProduct); // Save snapshot
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      ...products.map((p) => p.category).toSet().toList()
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory'),
        backgroundColor: Colors.blue.shade800,
        elevation: 10,
        actions: [
          IconButton(
            icon: Icon(Icons.dashboard, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DashboardScreen(products: products)),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      drawer: MenuDrawer(), // Use the MenuDrawer widget
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or category...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _filterProducts,
                  ),
                ),
                SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: _sortProducts,
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
                    PopupMenuItem(
                        value: 'Category', child: Text('Sort by Category')),
                    PopupMenuItem(
                        value: 'Quantity', child: Text('Sort by Quantity')),
                    PopupMenuItem(value: 'Price', child: Text('Sort by Price')),
                  ],
                  icon: Icon(Icons.sort, color: Colors.blue.shade800),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedCategory,
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) => _filterByCategory(value!),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(child: Text('No products found.'))
                    : ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          );
          _fetchProducts();
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue.shade800,
        elevation: 5,
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isLowStock = product.quantity <= product.minQuantity;

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLowStock)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Low Stock',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(height: 8),
            Text(
              product.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Category: ${product.category}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.inventory, size: 18, color: Colors.blue.shade800),
                SizedBox(width: 8),
                Text(
                  'Quantity: ${product.quantity} ${product.unit}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning, size: 18, color: Colors.orange.shade800),
                SizedBox(width: 8),
                Text(
                  'Min Quantity: ${product.minQuantity} ${product.unit}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Price: \$${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _updateProductQuantity(product, product.quantity - 1);
                  },
                  icon: Icon(Icons.remove, size: 18),
                  label: Text('Remove'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _updateProductQuantity(product, product.quantity + 1);
                  },
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
