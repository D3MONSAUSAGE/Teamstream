import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teamstream/models/product.dart';
import 'package:teamstream/pages/inventory/reports_screen.dart';
import 'dart:math'; // Import for Random

class DashboardScreen extends StatelessWidget {
  final List<Product> products;

  const DashboardScreen({required this.products, super.key});

  @override
  Widget build(BuildContext context) {
    final lowStockProducts =
        products.where((p) => p.quantity <= p.minQuantity).toList();
    final totalInventoryValue =
        products.fold(0.0, (sum, p) => sum + (p.price * p.quantity));

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blue.shade800,
        elevation: 10,
        actions: [
          IconButton(
            icon: Icon(Icons.assignment, color: Colors.white), // Reports icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReportsScreen(), // Navigate to ReportsScreen
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 16),
            _buildInventoryValueCard(totalInventoryValue),
            SizedBox(height: 16),
            _buildLowStockAlertCard(lowStockProducts),
            SizedBox(height: 16),
            _buildCategoryChart(products),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryValueCard(double totalValue) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Inventory Value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '\$${totalValue.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlertCard(List<Product> lowStockProducts) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Low Stock Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8),
            if (lowStockProducts.isEmpty) Text('No low stock items.'),
            if (lowStockProducts.isNotEmpty)
              ...lowStockProducts.map((product) {
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                      '${product.quantity} ${product.unit} (Min: ${product.minQuantity} ${product.unit})'),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(List<Product> products) {
    final categoryMap = <String, int>{};
    for (var product in products) {
      categoryMap[product.category] = (categoryMap[product.category] ?? 0) + 1;
    }

    final List<PieChartSectionData> pieChartSections =
        categoryMap.entries.map((entry) {
      return PieChartSectionData(
        color: _getRandomColor(),
        value: entry.value.toDouble(),
        title: '${entry.key}\n(${entry.value})',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: pieChartSections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRandomColor() {
    final colors = [
      Colors.blue.shade800,
      Colors.green.shade800,
      Colors.orange.shade800,
      Colors.red.shade800,
      Colors.purple.shade800,
      Colors.teal.shade800,
    ];
    return colors[Random().nextInt(colors.length)]; // Use Random from dart:math
  }
}
