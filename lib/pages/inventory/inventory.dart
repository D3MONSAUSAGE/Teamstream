import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() => _isLoading = true);
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
      await InventoryService.saveInventorySnapshot(updatedProduct);
      _showSnackBar('Quantity updated successfully!', isSuccess: true);
    } else {
      _showSnackBar('Failed to update quantity.', isError: true);
    }
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor:
            isSuccess ? Colors.green : (isError ? Colors.red : null),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...products.map((p) => p.category).toSet()];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Inventory',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DashboardScreen(products: products)),
              );
            },
            tooltip: 'Dashboard',
          ),
          IconButton(
            icon:
                const Icon(Icons.notifications, color: Colors.white, size: 28),
            onPressed: () {
              _showSnackBar('Notifications clicked - functionality TBD');
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Search by name or category...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.blueAccent),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: _filterProducts,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: _sortProducts,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                        value: 'Name',
                        child:
                            Text('Sort by Name', style: GoogleFonts.poppins())),
                    PopupMenuItem(
                        value: 'Category',
                        child: Text('Sort by Category',
                            style: GoogleFonts.poppins())),
                    PopupMenuItem(
                        value: 'Quantity',
                        child: Text('Sort by Quantity',
                            style: GoogleFonts.poppins())),
                    PopupMenuItem(
                        value: 'Price',
                        child: Text('Sort by Price',
                            style: GoogleFonts.poppins())),
                  ],
                  icon: const Icon(Icons.sort, color: Colors.blueAccent),
                  tooltip: 'Sort Options',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category, style: GoogleFonts.poppins()),
                );
              }).toList(),
              onChanged: (value) => _filterByCategory(value!),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent))
                : filteredProducts.isEmpty
                    ? Center(
                        child: Text('No products found.',
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.grey[600])))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12.0),
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
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
          _fetchProducts();
        },
        backgroundColor: Colors.blueAccent,
        elevation: 5,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isLowStock = product.quantity <= product.minQuantity;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLowStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Low Stock',
                  style: GoogleFonts.poppins(
                    color: Colors.red[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Category: ${product.category}',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.inventory, size: 18, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  'Quantity: ${product.quantity} ${product.unit}',
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Min Quantity: ${product.minQuantity} ${product.unit}',
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Price: \$${product.price.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      _updateProductQuantity(product, product.quantity - 1),
                  icon: const Icon(Icons.remove, size: 18),
                  label: Text('Remove', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _updateProductQuantity(product, product.quantity + 1),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Add', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
