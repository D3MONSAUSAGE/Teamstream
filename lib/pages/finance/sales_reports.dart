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
    setState(() {
      isLoading = true;
    });

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

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredSales = _applyFilters();

    return Scaffold(
      appBar: AppBar(title: const Text("Daily Sales Reports")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔹 Upload Sales Report Button
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton.icon(
                    onPressed: _uploadSalesReport,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Sales Report"),
                  ),
                ),

                // 🔹 Sales Trends Chart
                if (filteredSales.isNotEmpty)
                  SizedBox(
                    height: 250,
                    child: SfCartesianChart(
                      primaryXAxis: DateTimeAxis(),
                      title: ChartTitle(text: "Sales Trends"),
                      legend: Legend(isVisible: true),
                      series: <CartesianSeries<Map<String, dynamic>, DateTime>>[
                        LineSeries<Map<String, dynamic>, DateTime>(
                          dataSource: filteredSales,
                          xValueMapper: (data, _) =>
                              DateTime.parse(data["date"]),
                          yValueMapper: (data, _) =>
                              double.tryParse(data["gross_sales"].toString()) ??
                              0,
                          markerSettings: const MarkerSettings(isVisible: true),
                          name: "Gross Sales",
                        ),
                      ],
                    ),
                  ),

                // 🔹 Date Filters
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text(filterStartDate == null
                              ? "Start Date"
                              : DateFormat.yMMMd().format(filterStartDate!)),
                          leading: const Icon(Icons.date_range),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                filterStartDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: Text(filterEndDate == null
                              ? "End Date"
                              : DateFormat.yMMMd().format(filterEndDate!)),
                          leading: const Icon(Icons.date_range),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                filterEndDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 Sales Data Table
                Expanded(
                  child: filteredSales.isEmpty
                      ? const Center(child: Text("No sales data available."))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            border: TableBorder.all(),
                            columns: const [
                              DataColumn(label: Text("Date")),
                              DataColumn(label: Text("Gross Sales")),
                              DataColumn(label: Text("Net Sales")),
                              DataColumn(label: Text("Total Taxes")),
                              DataColumn(label: Text("Labor Cost")),
                              DataColumn(label: Text("Order Count")),
                              DataColumn(label: Text("Labor Hours")),
                              DataColumn(label: Text("Labor %")),
                              DataColumn(label: Text("Total Discounts")),
                              DataColumn(label: Text("Voids")),
                              DataColumn(label: Text("Refunds")),
                              DataColumn(label: Text("Tips Collected")),
                              DataColumn(label: Text("Cash Sales")),
                              DataColumn(label: Text("Avg Order Value")),
                              DataColumn(label: Text("Sales per Labor Hr")),
                            ],
                            rows: filteredSales.map((data) {
                              return DataRow(cells: [
                                DataCell(Text(DateFormat('yyyy-MM-dd')
                                    .format(DateTime.parse(data["date"])))),
                                DataCell(Text("\$${data["gross_sales"]}")),
                                DataCell(Text("\$${data["net_sales"]}")),
                                DataCell(Text("\$${data["total_taxes"]}")),
                                DataCell(Text("\$${data["labor_cost"]}")),
                                DataCell(Text("${data["order_count"]}")),
                                DataCell(Text("${data["labor_hours"]} hrs")),
                                DataCell(Text("${data["labor_percent"]}%")),
                                DataCell(Text("\$${data["total_discounts"]}")),
                                DataCell(Text("\$${data["voids"]}")),
                                DataCell(Text("\$${data["refunds"]}")),
                                DataCell(Text("\$${data["tips_collected"]}")),
                                DataCell(Text("\$${data["cash_sales"]}")),
                                DataCell(Text("\$${data["avg_order_value"]}")),
                                DataCell(
                                    Text("\$${data["sales_per_labor_hour"]}")),
                              ]);
                            }).toList(),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
