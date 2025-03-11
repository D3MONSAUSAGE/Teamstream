import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teamstream/models/product.dart';
import 'package:teamstream/services/pocketbase/inventory_service.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
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
    setState(() {
      _isLoading = true;
    });
    final items = await InventoryService.fetchProducts();
    setState(() {
      products = items;
      _isLoading = false;
    });
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
      [
        'Name',
        'Category',
        'Quantity',
        'Unit',
        'Price',
        'Min Quantity'
      ], // Header
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
        '/storage/emulated/0/Download/inventory_report.csv'; // Adjust path as needed

    try {
      await File(filePath).writeAsString(csv);
      print('CSV file saved at $filePath');
    } catch (e) {
      print('Error saving CSV file: $e');
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
                  ], // Header
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
        '/storage/emulated/0/Download/inventory_report.pdf'; // Adjust path as needed
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    print('PDF file saved at $filePath');
  }

  @override
  Widget build(BuildContext context) {
    final lowStockProducts = getLowStockProducts();
    final inventorySummary = getInventorySummary();

    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Reports',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildLowStockReport(lowStockProducts),
            SizedBox(height: 16),
            _buildInventorySummaryReport(inventorySummary),
            SizedBox(height: 16),
            _buildStockLevelsChart(),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: exportProductsToCsv,
                  child: Text('Export as CSV'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: exportProductsToPdf,
                  child: Text('Export as PDF'),
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
            Text(
              'Low Stock Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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

  Widget _buildInventorySummaryReport(Map<String, dynamic> summary) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
                'Total Inventory Value: \$${summary['totalValue'].toStringAsFixed(2)}'),
            Text('Total Products: ${summary['totalProducts']}'),
            SizedBox(height: 8),
            Text('Categories:'),
            ...summary['categories'].entries.map((entry) {
              return Text('${entry.key}: ${entry.value}');
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStockLevelsChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: InventoryService.fetchInventoryHistory(
          products.first.id), // Fetch history for the first product
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No historical data available.');
        }

        final history = snapshot.data!;
        final data = history.map((entry) {
          return FlSpot(
            DateTime.parse(entry['date']).millisecondsSinceEpoch.toDouble(),
            entry['quantity'].toDouble(),
          );
        }).toList();

        return SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: data,
                  isCurved: true,
                  color: Colors.blue,
                  dotData: FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Text('${date.day}/${date.month}');
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
