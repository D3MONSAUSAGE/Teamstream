import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teamstream/models/product.dart';
import 'package:teamstream/services/pocketbase/inventory_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Product> products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final items = await InventoryService.fetchProducts();
      setState(() {
        products = items;
      });
    } catch (e) {
      print("❌ Error fetching products: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch product data.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Product> getLowStockProducts() {
    return products
        .where((product) => product.quantity <= product.minQuantity)
        .toList();
  }

  Map<String, dynamic> getInventorySummary() {
    final totalValue = products.fold(
        0.0, (sum, product) => sum + (product.price * product.quantity));
    final categories =
        products.map((product) => product.category).toSet().toList();
    final categoryCounts = <String, int>{};
    for (var category in categories) {
      categoryCounts[category] =
          products.where((product) => product.category == category).length;
    }

    return {
      'totalValue': totalValue,
      'totalProducts': products.length,
      'categories': categoryCounts,
    };
  }

  Future<void> exportProductsToCsv() async {
    final csvData = [
      ['Name', 'Category', 'Quantity', 'Unit', 'Price', 'Min Quantity'],
      ...products.map((product) => [
            product.name,
            product.category,
            product.quantity.toString(),
            product.unit,
            product.price.toStringAsFixed(2),
            product.minQuantity.toString(),
          ]),
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final filePath =
        '${Directory.systemTemp.path}/inventory_report.csv'; // Adjusted for better handling

    try {
      await File(filePath).writeAsString(csv);
      print('✅ CSV file saved at $filePath');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV file saved at: $filePath')),
      );
    } catch (e) {
      print('❌ Error saving CSV file: $e');
    }
  }

  Future<void> exportProductsToPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(level: 0, text: 'Inventory Report'),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  [
                    'Name',
                    'Category',
                    'Quantity',
                    'Unit',
                    'Price',
                    'Min Quantity'
                  ],
                  ...products.map((product) => [
                        product.name,
                        product.category,
                        product.quantity.toString(),
                        product.unit,
                        product.price.toStringAsFixed(2),
                        product.minQuantity.toString(),
                      ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    final filePath =
        '${Directory.systemTemp.path}/inventory_report.pdf'; // Adjusted for better handling
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    print('✅ PDF file saved at $filePath');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF file saved at: $filePath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowStockProducts = getLowStockProducts();
    final inventorySummary = getInventorySummary();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: const MenuDrawer(), // ✅ Integrated Menu Drawer for Navigation
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inventory Reports',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildLowStockReport(lowStockProducts),
                  const SizedBox(height: 16),
                  _buildInventorySummaryReport(inventorySummary),
                  const SizedBox(height: 16),
                  _buildStockLevelsChart(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: exportProductsToCsv,
                        child: const Text('Export as CSV'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: exportProductsToPdf,
                        child: const Text('Export as PDF'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLowStockReport(List<Product> lowStockProducts) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Low Stock Alerts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (lowStockProducts.isEmpty) const Text('No low stock items.'),
            if (lowStockProducts.isNotEmpty)
              ...lowStockProducts.map((product) {
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                      '${product.quantity} ${product.unit} (Min: ${product.minQuantity} ${product.unit})'),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySummaryReport(Map<String, dynamic> summary) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inventory Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                'Total Inventory Value: \$${summary['totalValue'].toStringAsFixed(2)}'),
            Text('Total Products: ${summary['totalProducts']}'),
            const SizedBox(height: 8),
            const Text('Categories:'),
            ...summary['categories'].entries.map((entry) {
              return Text('${entry.key}: ${entry.value}');
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStockLevelsChart() {
    if (products.isEmpty) {
      return const Text('No data available for stock levels.');
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: products.map((product) {
                return FlSpot(product.quantity.toDouble(), product.price);
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
