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
  String selectedFilter = "Week"; // ✅ Default to "Week"
  DateTime? selectedDate = DateTime.now();
  DateTime? startDate;
  DateTime? endDate;
  DateTime? uploadDate; // ✅ Date for the uploaded document
  DateTime? deleteDate; // ✅ Date for deleting a daily sale

  // Pagination variables
  // int _rowsPerPage = 10; // Removed unused field

  // Toggle button state
  String _selectedSeries = "Gross Sales"; // Default to Gross Sales

  // Dark mode state
  bool isDarkMode = false;

  // Search query
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadSalesData();
  }

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

  void _applyFilters() {
    setState(() {});
  }

  /// ✅ Returns the current week's Monday - Sunday date range for display
  String _getWeekDisplay() {
    if (selectedFilter == "Week" && selectedDate != null) {
      DateTime startOfWeek =
          selectedDate!.subtract(Duration(days: selectedDate!.weekday - 1));
      DateTime endOfWeek =
          startOfWeek.add(const Duration(days: 6)); // ✅ Monday - Sunday
      return "${DateFormat('MM/dd/yyyy').format(startOfWeek)} - ${DateFormat('MM/dd/yyyy').format(endOfWeek)}";
    }
    return "";
  }

  List<Map<String, dynamic>> _getFilteredSalesData() {
    List<Map<String, dynamic>> filtered = salesData;

    if (selectedFilter == "Week" && selectedDate != null) {
      DateTime startOfWeek =
          selectedDate!.subtract(Duration(days: selectedDate!.weekday - 1));
      DateTime endOfWeek =
          startOfWeek.add(const Duration(days: 6)); // ✅ Monday - Sunday
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate
                .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            reportDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
    } else if (selectedFilter == "Day" && selectedDate != null) {
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return DateFormat('yyyy-MM-dd').format(reportDate) ==
            DateFormat('yyyy-MM-dd').format(selectedDate!);
      }).toList();
    } else if (selectedFilter == "Month" && selectedDate != null) {
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate.year == selectedDate!.year &&
            reportDate.month == selectedDate!.month;
      }).toList();
    } else if (selectedFilter == "Year" && selectedDate != null) {
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate.year == selectedDate!.year;
      }).toList();
    } else if (selectedFilter == "Date Range" &&
        startDate != null &&
        endDate != null) {
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate.isAfter(startDate!) && reportDate.isBefore(endDate!);
      }).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((data) {
        return data['date'].toString().contains(searchQuery) ||
            data['gross_sales'].toString().contains(searchQuery) ||
            data['net_sales'].toString().contains(searchQuery) ||
            data['total_taxes'].toString().contains(searchQuery) ||
            data['tips_collected'].toString().contains(searchQuery) ||
            data['order_count'].toString().contains(searchQuery) ||
            data['voids'].toString().contains(searchQuery) ||
            data['refunds'].toString().contains(searchQuery) ||
            data['cash_sales'].toString().contains(searchQuery);
      }).toList();
    }

    return filtered;
  }

  void _uploadSalesReport() async {
    if (uploadDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please select a date for the upload.")),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      bool success = await DailySalesService.uploadSalesReport(
        result.files.first,
        uploadDate!, // Pass the selected upload date
      );
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

  void _deleteDailySale() async {
    if (deleteDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please select a date to delete.")),
      );
      return;
    }

    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Daily Sale"),
        content: const Text("Are you sure you want to delete this record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      bool success = await DailySalesService.deleteDailySale(deleteDate!);
      if (success) {
        loadSalesData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Daily sale deleted successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to delete daily sale.")),
        );
      }
    }
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  Widget _buildFilterUI() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Filter Sales Data",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedFilter,
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                  selectedDate = DateTime.now();
                  startDate = null;
                  endDate = null;
                });
              },
              items: ["Day", "Week", "Month", "Year", "Date Range"]
                  .map((filter) =>
                      DropdownMenuItem(value: filter, child: Text(filter)))
                  .toList(),
            ),
            if (selectedFilter == "Week")
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Current Week: ${_getWeekDisplay()}",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey),
                ),
              ),
            const SizedBox(height: 8),
            if (selectedFilter != "Date Range")
              _buildDatePicker("Select $selectedFilter",
                  (date) => setState(() => selectedDate = date)),
            if (selectedFilter == "Date Range") ...[
              _buildDatePicker(
                  "Start Date", (date) => setState(() => startDate = date)),
              _buildDatePicker(
                  "End Date", (date) => setState(() => endDate = date)),
            ],
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Apply Filter"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, Function(DateTime) onPicked) {
    return ElevatedButton(
      onPressed: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
      child: Text(label),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Upload Daily Sales",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDatePicker("Select Date for Upload",
                (date) => setState(() => uploadDate = date)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadSalesReport,
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload Sales Report"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteSection() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Delete Daily Sale",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDatePicker("Select Date to Delete",
                (date) => setState(() => deleteDate = date)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deleteDailySale,
                icon: const Icon(Icons.delete),
                label: const Text("Delete Daily Sale"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(List<Map<String, dynamic>> salesData) {
    return Column(
      children: [
        // Toggle buttons for selecting the series
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSeriesToggleButton("Gross Sales"),
            _buildSeriesToggleButton("Net Sales"),
            _buildSeriesToggleButton("Total Taxes"),
          ],
        ),
        const SizedBox(height: 10),
        // Chart
        SfCartesianChart(
          primaryXAxis: DateTimeAxis(
            title: AxisTitle(text: 'Date'),
            dateFormat: DateFormat('MM/dd'),
          ),
          primaryYAxis: NumericAxis(
            title: AxisTitle(text: _selectedSeries),
          ),
          title: ChartTitle(text: 'Sales Trends'),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <CartesianSeries>[
            LineSeries<Map<String, dynamic>, DateTime>(
              dataSource: salesData,
              xValueMapper: (data, _) => DateTime.parse(data['date']),
              yValueMapper: (data, _) {
                switch (_selectedSeries) {
                  case "Gross Sales":
                    return double.tryParse(data['gross_sales'].toString()) ?? 0;
                  case "Net Sales":
                    return double.tryParse(data['net_sales'].toString()) ?? 0;
                  case "Total Taxes":
                    return double.tryParse(data['total_taxes'].toString()) ?? 0;
                  default:
                    return 0;
                }
              },
              name: _selectedSeries,
              markerSettings: const MarkerSettings(isVisible: true),
              dataLabelSettings: const DataLabelSettings(isVisible: true),
              color: Colors.blueAccent,
            ),
          ],
        ),
      ],
    );
  }

  void _toggleSeries(String series) {
    setState(() {
      _selectedSeries = series;
    });
  }

  // Helper method to build toggle buttons
  Widget _buildSeriesToggleButton(String series) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () => _toggleSeries(series),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _selectedSeries == series ? Colors.blueAccent : Colors.grey[300],
          foregroundColor:
              _selectedSeries == series ? Colors.white : Colors.black,
        ),
        child: Text(series),
      ),
    );
  }

  Widget _buildSalesTable(List<Map<String, dynamic>> salesData) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Gross Sales')),
          DataColumn(label: Text('Net Sales')),
          DataColumn(label: Text('Total Taxes')),
          DataColumn(label: Text('Tips Collected')),
          DataColumn(label: Text('Order Count')),
          DataColumn(label: Text('Voids')),
          DataColumn(label: Text('Refunds')),
          DataColumn(label: Text('Cash Sales')),
        ],
        rows: salesData.map((data) {
          return DataRow(
            color: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                if (salesData.indexOf(data) % 2 == 0) {
                  return Colors.grey[200]!;
                }
                return Colors.white;
              },
            ),
            cells: [
              DataCell(Text(DateFormat('MM/dd/yyyy')
                  .format(DateTime.parse(data['date'])))),
              DataCell(Text(data['gross_sales'].toString())),
              DataCell(Text(data['net_sales'].toString())),
              DataCell(Text(data['total_taxes'].toString())),
              DataCell(Text(data['tips_collected'].toString())),
              DataCell(Text(data['order_count'].toString())),
              DataCell(Text(data['voids'].toString())),
              DataCell(Text(data['refunds'].toString())),
              DataCell(Text(data['cash_sales'].toString())),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredSales = _getFilteredSalesData();

    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Daily Sales Reports"),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orangeAccent, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleDarkMode,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Add settings functionality
              },
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildUploadSection(), // ✅ Upload section
                    const SizedBox(height: 20),
                    _buildDeleteSection(), // ✅ Delete section
                    const SizedBox(height: 20),
                    _buildFilterUI(), // ✅ Filter and view section
                    const SizedBox(height: 20),
                    _buildSearchBar(), // ✅ Search bar
                    const SizedBox(height: 20),
                    if (filteredSales.isNotEmpty) ...[
                      _buildSalesChart(filteredSales),
                      const SizedBox(height: 20),
                      _buildSalesTable(filteredSales),
                    ] else
                      const Center(
                        child: Text(
                          "No sales data available for the selected filter.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Add functionality (e.g., upload report)
          },
          backgroundColor: Colors.orangeAccent,
          child: const Icon(Icons.upload_file),
        ),
      ),
    );
  }
}
