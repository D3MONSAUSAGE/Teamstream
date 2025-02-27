import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:teamstream/services/pocketbase/daily_sales_service.dart';

class SalesReportsPage extends StatefulWidget {
  const SalesReportsPage({super.key});

  @override
  SalesReportsPageState createState() => SalesReportsPageState();
}

class SalesReportsPageState extends State<SalesReportsPage> {
  List<Map<String, dynamic>> salesData = [];
  bool isLoading = true;
  DateTime? filterStartDate;
  DateTime? filterEndDate;

  @override
  void initState() {
    super.initState();
    loadSalesData();
  }

  /// 🔹 Fetch sales data from PocketBase
  void loadSalesData() async {
    List<Map<String, dynamic>> fetchedData =
        await DailySalesService.fetchSalesData();
    setState(() {
      salesData = fetchedData;
      isLoading = false;
    });
  }

  /// 🔹 Apply Date Filters
  List<Map<String, dynamic>> _applyFilters() {
    List<Map<String, dynamic>> filtered = salesData;

    if (filterStartDate != null) {
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate.isAtSameMomentAs(filterStartDate!) ||
            reportDate.isAfter(filterStartDate!);
      }).toList();
    }

    if (filterEndDate != null) {
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate.isAtSameMomentAs(filterEndDate!) ||
            reportDate.isBefore(filterEndDate!);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredSales = _applyFilters();

    return Scaffold(
      appBar: AppBar(title: const Text("Daily Sales Reports")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton.icon(
                    onPressed: _uploadSalesReport,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Sales Report"),
                  ),
                ),

                /// 🔹 Sales Trends Chart
                if (filteredSales.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 250,
                      child: SfCartesianChart(
                        title: ChartTitle(text: "Sales Trends"),
                        legend: Legend(isVisible: true),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        primaryXAxis: DateTimeAxis(),
                        series: <CartesianSeries<Map<String, dynamic>,
                            DateTime>>[
                          LineSeries<Map<String, dynamic>, DateTime>(
                            dataSource: filteredSales,
                            xValueMapper: (data, _) =>
                                DateTime.parse(data["date"]),
                            yValueMapper: (data, _) =>
                                double.tryParse(
                                    data["gross_sales"].toString()) ??
                                0,
                            markerSettings:
                                const MarkerSettings(isVisible: true),
                            color: Colors.blueAccent,
                            name: "Gross Sales",
                          ),
                        ],
                      ),
                    ),
                  ),

                /// 🔹 Sales Data Table
                Expanded(
                  child: filteredSales.isEmpty
                      ? const Center(child: Text("No sales data available."))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 12,
                            border: TableBorder.all(color: Colors.grey[300]!),
                            headingRowColor: MaterialStateColor.resolveWith(
                                (states) => Colors.blueAccent.shade100),
                            columns: const [
                              DataColumn(
                                  label: Text("Date",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text("Gross Sales",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text("Net Sales",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text("Total Taxes",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text("Labor Cost",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text("Order Count",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: filteredSales.map((data) {
                              return DataRow(
                                color: MaterialStateColor.resolveWith(
                                  (states) =>
                                      filteredSales.indexOf(data) % 2 == 0
                                          ? Colors.grey.shade200
                                          : Colors.white,
                                ),
                                cells: [
                                  DataCell(Text(DateFormat('yyyy-MM-dd')
                                      .format(DateTime.parse(data["date"])))),
                                  DataCell(Text("\$${data["gross_sales"]}")),
                                  DataCell(Text("\$${data["net_sales"]}")),
                                  DataCell(Text("\$${data["total_taxes"]}")),
                                  DataCell(Text("\$${data["labor_cost"]}")),
                                  DataCell(Text("${data["order_count"]}")),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  /// 🔹 Upload Sales Report
  void _uploadSalesReport() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      bool success =
          await DailySalesService.uploadSalesReport(result.files.first);
      if (success) {
        loadSalesData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("✅ Sales report uploaded successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to upload sales report.")),
        );
      }
    }
  }
}
