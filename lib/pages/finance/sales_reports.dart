import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String selectedFilter = "Week";
  DateTime? selectedDate = DateTime.now();
  DateTime? startDate;
  DateTime? endDate;
  DateTime? uploadDate; // Added to store selected upload date
  String _selectedSeries = "Gross Sales";
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() => isLoading = true);
    try {
      salesData =
          await DailySalesService.fetchDailySales(); // Updated method name
    } catch (e) {
      _showSnackBar('Error fetching sales data: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredSalesData() {
    List<Map<String, dynamic>> filtered = List.from(salesData);

    if (selectedFilter == "Week" && selectedDate != null) {
      DateTime startOfWeek =
          selectedDate!.subtract(Duration(days: selectedDate!.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate
                .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            reportDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
    } else if (selectedFilter == "Day" && selectedDate != null) {
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate.day == selectedDate!.day &&
            reportDate.month == selectedDate!.month &&
            reportDate.year == selectedDate!.year;
      }).toList();
    } else if (selectedFilter == "Month" && selectedDate != null) {
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate.month == selectedDate!.month &&
            reportDate.year == selectedDate!.year;
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

    return filtered;
  }

  Future<void> _uploadSalesReport() async {
    uploadDate = await _pickDate('Select Date for Upload');
    if (uploadDate == null) {
      _showSnackBar('No date selected for upload', isError: true);
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() => isLoading = true); // Show loading
        bool success = await DailySalesService.uploadSalesReport(
          result.files.single,
          uploadDate!, // Pass the selected date
        );
        if (success) {
          await _loadSalesData(); // Refresh data
          _showSnackBar('Sales report uploaded successfully', isSuccess: true);
        } else {
          _showSnackBar('Failed to upload sales report', isError: true);
        }
      } else {
        _showSnackBar('No file selected', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error uploading report: $e', isError: true);
    } finally {
      setState(() => isLoading = false); // Hide loading
    }
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isSuccess ? Colors.green : (isError ? Colors.red : null),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<DateTime?> _pickDate(String label) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
        ),
        child: child!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredSales = _getFilteredSalesData();
    return Theme(
      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'Daily Sales Reports',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => setState(() => isDarkMode = !isDarkMode),
              tooltip: 'Toggle Dark Mode',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
              onPressed: _loadSalesData,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 12),
                  _buildFilterSection(),
                  const SizedBox(height: 12),
                  _buildUploadSection(),
                  const SizedBox(height: 12),
                  _buildSalesChart(filteredSales),
                  const SizedBox(height: 12),
                  _buildSalesTable(filteredSales),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _uploadSalesReport,
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.upload, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyze your daily sales performance',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Sales Data',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedFilter,
              decoration: InputDecoration(
                labelText: 'Filter Type',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: ["Day", "Week", "Month", "Year", "Date Range"]
                  .map((filter) => DropdownMenuItem(
                        value: filter,
                        child: Text(filter, style: GoogleFonts.poppins()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                  selectedDate = DateTime.now();
                  startDate = null;
                  endDate = null;
                });
              },
            ),
            const SizedBox(height: 12),
            if (selectedFilter == "Week" && selectedDate != null)
              Text(
                "Week: ${DateFormat('MMM d').format(selectedDate!.subtract(Duration(days: selectedDate!.weekday - 1)))} - ${DateFormat('MMM d').format(selectedDate!.subtract(Duration(days: selectedDate!.weekday - 1)).add(const Duration(days: 6)))}",
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
            if (selectedFilter != "Date Range")
              _buildDatePicker("Select $selectedFilter",
                  (date) => setState(() => selectedDate = date)),
            if (selectedFilter == "Date Range") ...[
              _buildDatePicker(
                  "Start Date", (date) => setState(() => startDate = date)),
              _buildDatePicker(
                  "End Date", (date) => setState(() => endDate = date)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Daily Sales',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              uploadDate != null
                  ? 'Selected Date: ${DateFormat('MMM d, yyyy').format(uploadDate!)}'
                  : 'No date selected',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, Function(DateTime) onPicked) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ElevatedButton(
        onPressed: () async {
          DateTime? picked = await _pickDate(label);
          if (picked != null) onPicked(picked);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(color: Colors.blue[900]),
        ),
      ),
    );
  }

  Widget _buildSalesChart(List<Map<String, dynamic>> salesData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Trends',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildSeriesToggleButton("Gross Sales"),
                _buildSeriesToggleButton("Net Sales"),
                _buildSeriesToggleButton("Total Taxes"),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat('MMM d'),
                  intervalType: DateTimeIntervalType.days,
                ),
                primaryYAxis: NumericAxis(labelFormat: '\${value}'),
                series: <CartesianSeries>[
                  LineSeries<Map<String, dynamic>, DateTime>(
                    dataSource: salesData,
                    xValueMapper: (data, _) => DateTime.parse(data['date']),
                    yValueMapper: (data, _) {
                      switch (_selectedSeries) {
                        case "Gross Sales":
                          return data['gross_sales'] as double? ?? 0.0;
                        case "Net Sales":
                          return data['net_sales'] as double? ?? 0.0;
                        case "Total Taxes":
                          return data['total_taxes'] as double? ?? 0.0;
                        default:
                          return 0.0;
                      }
                    },
                    color: Colors.blueAccent,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesToggleButton(String series) {
    return ElevatedButton(
      onPressed: () => setState(() => _selectedSeries = series),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _selectedSeries == series ? Colors.blueAccent : Colors.grey[300],
        foregroundColor:
            _selectedSeries == series ? Colors.white : Colors.blue[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        series,
        style: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }

  Widget _buildSalesTable(List<Map<String, dynamic>> salesData) {
    if (salesData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No sales data available for the selected filter',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowColor: MaterialStatePropertyAll(
                    Colors.blueAccent.withOpacity(0.1)),
                columns: [
                  DataColumn(
                      label: Text('Date',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900]))),
                  DataColumn(
                      label: Text('Gross',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900]))),
                  DataColumn(
                      label: Text('Net',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900]))),
                  DataColumn(
                      label: Text('Taxes',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900]))),
                ],
                rows: salesData.map((data) {
                  DateTime date = DateTime.parse(data['date']);
                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormat('MMM d').format(date),
                          style: GoogleFonts.poppins(fontSize: 12))),
                      DataCell(Text(
                          '\$${data['gross_sales'].toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(fontSize: 12))),
                      DataCell(Text('\$${data['net_sales'].toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(fontSize: 12))),
                      DataCell(Text(
                          '\$${data['total_taxes'].toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(fontSize: 12))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
