import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teamstream/models/product.dart';
import 'package:teamstream/pages/inventory/reports_screen.dart';
import 'dart:math';

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Inventory Dashboard',
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
            icon:
                const Icon(Icons.notifications, color: Colors.white, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notifications clicked - functionality TBD',
                      style: GoogleFonts.poppins()),
                  backgroundColor: Colors.blueAccent,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Overview',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Key metrics at a glance.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            _buildInventoryValueCard(totalInventoryValue),
            const SizedBox(height: 20),
            _buildLowStockAlertCard(lowStockProducts),
            const SizedBox(height: 20),
            _buildCategoryChart(products),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryValueCard(double totalValue) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Inventory Value',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\$${totalValue.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlertCard(List<Product> lowStockProducts) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Low Stock Alerts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            if (lowStockProducts.isEmpty)
              Text(
                'No low stock items.',
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
            if (lowStockProducts.isNotEmpty)
              ...lowStockProducts.map((product) {
                return ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(
                    product.name,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${product.quantity} ${product.unit} (Min: ${product.minQuantity} ${product.unit})',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[700]),
                  ),
                );
              }),
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
        titleStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products by Category',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
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
      Colors.blueAccent,
      Colors.green,
      Colors.orange,
      Colors.redAccent,
      Colors.purple,
      Colors.teal,
    ];
    return colors[Random().nextInt(colors.length)];
  }
}
