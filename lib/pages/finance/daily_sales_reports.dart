import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/daily_sales_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:teamstream/utils/constants.dart';

class DailySalesReportsPage extends StatefulWidget {
  const DailySalesReportsPage({super.key});

  @override
  DailySalesReportsPageState createState() => DailySalesReportsPageState();
}

class DailySalesReportsPageState extends State<DailySalesReportsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> salesData = [];
  bool isLoading = true;
  String selectedFilter = "This Week";
  DateTime? selectedDate = DateTime.now();
  DateTime? startDate;
  DateTime? endDate;
  DateTime? uploadDate;
  String _selectedSeries = "Gross Sales";
  bool isDarkMode = false;
  String _sortColumn = "Date";
  bool _sortAscending = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // For current week's sales summary
  double currentWeekGrossSales = 0.0;
  double currentWeekNetSales = 0.0;
  double currentWeekTotalTaxes = 0.0;
  double currentWeekLaborCost = 0.0;
  double currentWeekOrderCount = 0.0;
  double currentWeekAvgOrderValue = 0.0;

  // For selected period's sales summary
  double selectedPeriodGrossSales = 0.0;
  double selectedPeriodNetSales = 0.0;
  double selectedPeriodTotalTaxes = 0.0;
  double selectedPeriodLaborCost = 0.0;
  double selectedPeriodOrderCount = 0.0;
  double selectedPeriodAvgOrderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadSalesData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesData() async {
    setState(() => isLoading = true);
    try {
      salesData = await DailySalesService.fetchDailySales();
      print("Updated salesData: $salesData");
      _calculateCurrentWeekSales();
      _calculateSelectedPeriodSales();
      print("Current Week Gross Sales: $currentWeekGrossSales");
      print("Selected Period Gross Sales: $selectedPeriodGrossSales");
      _animationController.forward();
    } catch (e) {
      _showSnackBar('Error fetching sales data: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _calculateCurrentWeekSales() {
    DateTime now = DateTime.now().toUtc();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    List<Map<String, dynamic>> currentWeekData = salesData.where((data) {
      DateTime reportDate = DateTime.parse(data["date"]);
      return reportDate
              .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          reportDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();

    currentWeekGrossSales = currentWeekData.fold(
        0.0, (sum, data) => sum + (data['gross_sales'] as double? ?? 0.0));
    currentWeekNetSales = currentWeekData.fold(
        0.0, (sum, data) => sum + (data['net_sales'] as double? ?? 0.0));
    currentWeekTotalTaxes = currentWeekData.fold(
        0.0, (sum, data) => sum + (data['total_taxes'] as double? ?? 0.0));
    currentWeekLaborCost = currentWeekData.fold(
        0.0, (sum, data) => sum + (data['labor_cost'] as double? ?? 0.0));
    currentWeekOrderCount = currentWeekData.fold(
        0.0, (sum, data) => sum + (data['order_count'] as double? ?? 0.0));
    currentWeekAvgOrderValue = currentWeekData.isNotEmpty
        ? currentWeekGrossSales /
            (currentWeekOrderCount == 0 ? 1 : currentWeekOrderCount)
        : 0.0;
  }

  void _calculateSelectedPeriodSales() {
    List<Map<String, dynamic>> filteredSales = _getFilteredSalesData();
    selectedPeriodGrossSales = filteredSales.fold(
        0.0, (sum, data) => sum + (data['gross_sales'] as double? ?? 0.0));
    selectedPeriodNetSales = filteredSales.fold(
        0.0, (sum, data) => sum + (data['net_sales'] as double? ?? 0.0));
    selectedPeriodTotalTaxes = filteredSales.fold(
        0.0, (sum, data) => sum + (data['total_taxes'] as double? ?? 0.0));
    selectedPeriodLaborCost = filteredSales.fold(
        0.0, (sum, data) => sum + (data['labor_cost'] as double? ?? 0.0));
    selectedPeriodOrderCount = filteredSales.fold(
        0.0, (sum, data) => sum + (data['order_count'] as double? ?? 0.0));
    selectedPeriodAvgOrderValue = filteredSales.isNotEmpty
        ? selectedPeriodGrossSales /
            (selectedPeriodOrderCount == 0 ? 1 : selectedPeriodOrderCount)
        : 0.0;
  }

  List<Map<String, dynamic>> _getFilteredSalesData() {
    List<Map<String, dynamic>> filtered = List.from(salesData);
    DateTime now = DateTime.now().toUtc();

    if (selectedFilter == "This Week") {
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate
                .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            reportDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
    } else if (selectedFilter == "Last Week") {
      DateTime startOfLastWeek =
          now.subtract(Duration(days: now.weekday - 1 + 7));
      DateTime endOfLastWeek = startOfLastWeek.add(const Duration(days: 6));
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate
                .isAfter(startOfLastWeek.subtract(const Duration(days: 1))) &&
            reportDate.isBefore(endOfLastWeek.add(const Duration(days: 1)));
      }).toList();
    } else if (selectedFilter == "This Month") {
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate
                .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            reportDate.isBefore(endOfMonth.add(const Duration(days: 1)));
      }).toList();
    } else if (selectedFilter == "Last Month") {
      DateTime startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      DateTime endOfLastMonth = DateTime(now.year, now.month, 0);
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate
                .isAfter(startOfLastMonth.subtract(const Duration(days: 1))) &&
            reportDate.isBefore(endOfLastMonth.add(const Duration(days: 1)));
      }).toList();
    } else if (selectedFilter == "Day" && selectedDate != null) {
      DateTime selectedDateUtc = selectedDate!.toUtc();
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate.day == selectedDateUtc.day &&
            reportDate.month == selectedDateUtc.month &&
            reportDate.year == selectedDateUtc.year;
      }).toList();
    } else if (selectedFilter == "Month" && selectedDate != null) {
      DateTime selectedDateUtc = selectedDate!.toUtc();
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate.month == selectedDateUtc.month &&
            reportDate.year == selectedDateUtc.year;
      }).toList();
    } else if (selectedFilter == "Year" && selectedDate != null) {
      DateTime selectedDateUtc = selectedDate!.toUtc();
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate.year == selectedDateUtc.year;
      }).toList();
    } else if (selectedFilter == "Custom Range" &&
        startDate != null &&
        endDate != null) {
      DateTime startDateUtc = startDate!.toUtc();
      DateTime endDateUtc = endDate!.toUtc();
      filtered = filtered.where((data) {
        DateTime reportDate = DateTime.parse(data["date"]);
        return reportDate
                .isAfter(startDateUtc.subtract(const Duration(days: 1))) &&
            reportDate.isBefore(endDateUtc.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort the filtered data
    filtered.sort((a, b) {
      int compare = 0;
      switch (_sortColumn) {
        case "Date":
          compare =
              DateTime.parse(a['date']).compareTo(DateTime.parse(b['date']));
          break;
        case "Gross":
          compare = (a['gross_sales'] as double)
              .compareTo(b['gross_sales'] as double);
          break;
        case "Net":
          compare =
              (a['net_sales'] as double).compareTo(b['net_sales'] as double);
          break;
        case "Taxes":
          compare = (a['total_taxes'] as double)
              .compareTo(b['total_taxes'] as double);
          break;
        case "Labor Cost":
          compare =
              (a['labor_cost'] as double).compareTo(b['labor_cost'] as double);
          break;
        case "Order Count":
          compare = (a['order_count'] as double)
              .compareTo(b['order_count'] as double);
          break;
        case "Tips":
          compare = (a['tips_collected'] as double)
              .compareTo(b['tips_collected'] as double);
          break;
      }
      return _sortAscending ? compare : -compare;
    });

    print("Filtered sales data: $filtered");
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
        setState(() => isLoading = true);
        bool success = await DailySalesService.uploadSalesReport(
          result.files.single,
          uploadDate!.toUtc(),
        );
        if (success) {
          await _loadSalesData();
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
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteSalesRecord(DateTime date) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Confirm Delete',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete the sales record for ${DateFormat('MMM d, yyyy').format(date)}?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      bool success = await DailySalesService.deleteDailySale(date.toUtc());
      if (success) {
        await _loadSalesData();
        _showSnackBar('Sales record deleted successfully', isSuccess: true);
      } else {
        _showSnackBar('Failed to delete sales record', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error deleting sales record: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String?> _downloadPdf(String pdfUrl) async {
    try {
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/temp_sales_report.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error downloading PDF: $e', isError: true);
      return null;
    }
  }

  Future<void> _exportSalesData(List<Map<String, dynamic>> salesData) async {
    try {
      List<List<dynamic>> csvData = [
        [
          'Date',
          'Gross Sales',
          'Net Sales',
          'Total Taxes',
          'Labor Cost',
          'Order Count',
          'Labor Hours',
          'Labor Percent',
          'Total Discounts',
          'Voids',
          'Refunds',
          'Tips Collected',
          'Cash Sales',
          'Avg Order Value',
          'Sales per Labor Hour'
        ],
        ...salesData.map((data) => [
              DateFormat('MMM d, yyyy').format(DateTime.parse(data['date'])),
              data['gross_sales'].toString(),
              data['net_sales'].toString(),
              data['total_taxes'].toString(),
              data['labor_cost'].toString(),
              data['order_count'].toString(),
              data['labor_hours'].toString(),
              data['labor_percent'].toString(),
              data['total_discounts'].toString(),
              data['voids'].toString(),
              data['refunds'].toString(),
              data['tips_collected'].toString(),
              data['cash_sales'].toString(),
              data['avg_order_value'].toString(),
              data['sales_per_labor_hour'].toString(),
            ]),
      ];

      String csv = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csv);
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsBytes(bytes);

      _showSnackBar('Sales data exported to ${file.path}', isSuccess: true);
    } catch (e) {
      _showSnackBar('Error exporting sales data: $e', isError: true);
    }
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isSuccess
            ? Colors.green
            : (isError ? Colors.red : Colors.blueAccent),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<DateTime?> _pickDate(String label) async {
    DateTime? picked = await showDatePicker(
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
    return picked?.toUtc();
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
          iconTheme: const IconThemeData(color: Colors.white),
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
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white, size: 28),
              onPressed: () => _exportSalesData(filteredSales),
              tooltip: 'Export Sales Data',
            ),
          ],
        ),
        drawer: const MenuDrawer(),
        body: isLoading
            ? const Center(
                child: SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 50.0,
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildCurrentWeekSummary(),
                    const SizedBox(height: 16),
                    _buildSelectedPeriodSummary(),
                    const SizedBox(height: 16),
                    _buildHeaderSection(),
                    const SizedBox(height: 16),
                    _buildFilterSection(),
                    const SizedBox(height: 16),
                    _buildUploadSection(),
                    const SizedBox(height: 16),
                    _buildSalesCharts(filteredSales),
                    const SizedBox(height: 16),
                    _buildSalesTable(filteredSales),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _uploadSalesReport,
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.upload, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildCurrentWeekSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Week Sales Summary',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildSummaryItem(
                    'Gross Sales', currentWeekGrossSales, Colors.green),
                _buildSummaryItem(
                    'Net Sales', currentWeekNetSales, Colors.blue),
                _buildSummaryItem(
                    'Total Taxes', currentWeekTotalTaxes, Colors.orange),
                _buildSummaryItem(
                    'Labor Cost', currentWeekLaborCost, Colors.red),
                _buildSummaryItem(
                    'Order Count', currentWeekOrderCount, Colors.purple),
                _buildSummaryItem(
                    'Avg Order Value', currentWeekAvgOrderValue, Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPeriodSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Period Sales Summary',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildSummaryItem(
                    'Gross Sales', selectedPeriodGrossSales, Colors.green),
                _buildSummaryItem(
                    'Net Sales', selectedPeriodNetSales, Colors.blue),
                _buildSummaryItem(
                    'Total Taxes', selectedPeriodTotalTaxes, Colors.orange),
                _buildSummaryItem(
                    'Labor Cost', selectedPeriodLaborCost, Colors.red),
                _buildSummaryItem(
                    'Order Count', selectedPeriodOrderCount, Colors.purple),
                _buildSummaryItem('Avg Order Value',
                    selectedPeriodAvgOrderValue, Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.28,
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label.contains('Count')
                ? value.toStringAsFixed(0)
                : '\$${value.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
              items: [
                "This Week",
                "Last Week",
                "This Month",
                "Last Month",
                "Day",
                "Month",
                "Year",
                "Custom Range"
              ]
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
                  _calculateSelectedPeriodSales();
                });
              },
            ),
            const SizedBox(height: 12),
            if (selectedFilter == "This Week" || selectedFilter == "Last Week")
              Text(
                selectedFilter == "This Week"
                    ? "Week: ${DateFormat('MMM d').format(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)))} - ${DateFormat('MMM d').format(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).add(const Duration(days: 6)))}"
                    : "Week: ${DateFormat('MMM d').format(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 + 7)))} - ${DateFormat('MMM d').format(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 + 7)).add(const Duration(days: 6)))}",
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
            if (selectedFilter == "This Month" ||
                selectedFilter == "Last Month")
              Text(
                selectedFilter == "This Month"
                    ? "Month: ${DateFormat('MMMM yyyy').format(DateTime.now())}"
                    : "Month: ${DateFormat('MMMM yyyy').format(DateTime(DateTime.now().year, DateTime.now().month - 1))}",
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
            if (selectedFilter == "Day" ||
                selectedFilter == "Month" ||
                selectedFilter == "Year")
              _buildDatePicker("Select $selectedFilter", (date) {
                setState(() {
                  selectedDate = date;
                  _calculateSelectedPeriodSales();
                });
              }),
            if (selectedFilter == "Custom Range") ...[
              _buildDatePicker("Start Date", (date) {
                setState(() {
                  startDate = date;
                  if (endDate != null) _calculateSelectedPeriodSales();
                });
              }),
              _buildDatePicker("End Date", (date) {
                setState(() {
                  endDate = date;
                  if (startDate != null) _calculateSelectedPeriodSales();
                });
              }),
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

  Widget _buildSalesCharts(List<Map<String, dynamic>> salesData) {
    return Column(
      children: [
        _buildLineChart(salesData),
        const SizedBox(height: 16),
        _buildBarChart(salesData),
        const SizedBox(height: 16),
        _buildPieChart(salesData),
        const SizedBox(height: 16),
        _buildLaborChart(salesData),
        const SizedBox(height: 16),
        _buildTaxChart(salesData), // Added tax chart
      ],
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> salesData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Trends (Line Chart)',
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
                _buildSeriesToggleButton("Labor Cost"),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat('MMM d'),
                  intervalType: DateTimeIntervalType.days,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  labelFormat: '\${value}',
                  majorGridLines:
                      const MajorGridLines(width: 0.5, color: Colors.grey),
                ),
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
                        case "Labor Cost":
                          return data['labor_cost'] as double? ?? 0.0;
                        default:
                          return 0.0;
                      }
                    },
                    color: Colors.blueAccent,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x : \$point.y',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> salesData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Sales Comparison (Bar Chart)',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat('MMM d'),
                  intervalType: DateTimeIntervalType.days,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  labelFormat: '\${value}',
                  majorGridLines:
                      const MajorGridLines(width: 0.5, color: Colors.grey),
                ),
                series: <CartesianSeries>[
                  ColumnSeries<Map<String, dynamic>, DateTime>(
                    dataSource: salesData,
                    xValueMapper: (data, _) => DateTime.parse(data['date']),
                    yValueMapper: (data, _) =>
                        data['gross_sales'] as double? ?? 0.0,
                    name: 'Gross Sales',
                    color: Colors.blueAccent,
                  ),
                  ColumnSeries<Map<String, dynamic>, DateTime>(
                    dataSource: salesData,
                    xValueMapper: (data, _) => DateTime.parse(data['date']),
                    yValueMapper: (data, _) =>
                        data['net_sales'] as double? ?? 0.0,
                    name: 'Net Sales',
                    color: Colors.green,
                  ),
                  ColumnSeries<Map<String, dynamic>, DateTime>(
                    dataSource: salesData,
                    xValueMapper: (data, _) => DateTime.parse(data['date']),
                    yValueMapper: (data, _) =>
                        data['labor_cost'] as double? ?? 0.0,
                    name: 'Labor Cost',
                    color: Colors.red,
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x : \$point.y',
                ),
                legend:
                    Legend(isVisible: true, position: LegendPosition.bottom),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> salesData) {
    if (salesData.isEmpty) return const SizedBox.shrink();

    double totalGross = salesData.fold(
        0.0, (sum, data) => sum + (data['gross_sales'] as double? ?? 0.0));
    double totalNet = salesData.fold(
        0.0, (sum, data) => sum + (data['net_sales'] as double? ?? 0.0));
    double totalTaxes = salesData.fold(
        0.0, (sum, data) => sum + (data['total_taxes'] as double? ?? 0.0));
    double totalLaborCost = salesData.fold(
        0.0, (sum, data) => sum + (data['labor_cost'] as double? ?? 0.0));

    List<Map<String, dynamic>> pieData = [
      {
        'category': 'Gross Sales',
        'value': totalGross,
        'color': Colors.blueAccent
      },
      {'category': 'Net Sales', 'value': totalNet, 'color': Colors.green},
      {'category': 'Total Taxes', 'value': totalTaxes, 'color': Colors.orange},
      {'category': 'Labor Cost', 'value': totalLaborCost, 'color': Colors.red},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Breakdown (Pie Chart)',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<Map<String, dynamic>, String>(
                    dataSource: pieData,
                    xValueMapper: (data, _) => data['category'],
                    yValueMapper: (data, _) => data['value'],
                    pointColorMapper: (data, _) => data['color'],
                    dataLabelMapper: (data, _) =>
                        '${data['category']}: \$${data['value'].toStringAsFixed(2)}',
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                  ),
                ],
                legend:
                    Legend(isVisible: true, position: LegendPosition.bottom),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaborChart(List<Map<String, dynamic>> salesData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Labor Metrics (Line Chart)',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat('MMM d'),
                  intervalType: DateTimeIntervalType.days,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  labelFormat: '\${value}',
                  majorGridLines:
                      const MajorGridLines(width: 0.5, color: Colors.grey),
                ),
                series: <CartesianSeries>[
                  LineSeries<Map<String, dynamic>, DateTime>(
                    dataSource: salesData,
                    xValueMapper: (data, _) => DateTime.parse(data['date']),
                    yValueMapper: (data, _) =>
                        data['labor_cost'] as double? ?? 0.0,
                    name: 'Labor Cost',
                    color: Colors.red,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                  LineSeries<Map<String, dynamic>, DateTime>(
                    dataSource: salesData,
                    xValueMapper: (data, _) => DateTime.parse(data['date']),
                    yValueMapper: (data, _) =>
                        data['sales_per_labor_hour'] as double? ?? 0.0,
                    name: 'Sales per Labor Hour',
                    color: Colors.purple,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x : \$point.y',
                ),
                legend:
                    Legend(isVisible: true, position: LegendPosition.bottom),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxChart(List<Map<String, dynamic>> salesData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tax Metrics (Line Chart)',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat('MMM d'),
                  intervalType: DateTimeIntervalType.days,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  labelFormat: '\${value}',
                  majorGridLines:
                      const MajorGridLines(width: 0.5, color: Colors.grey),
                ),
                series: <CartesianSeries>[
                  LineSeries<Map<String, dynamic>, DateTime>(
                    dataSource: salesData,
                    xValueMapper: (data, _) => DateTime.parse(data['date']),
                    yValueMapper: (data, _) =>
                        data['total_taxes'] as double? ?? 0.0,
                    name: 'Total Taxes',
                    color: Colors.orange,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x : \$point.y',
                ),
                legend:
                    Legend(isVisible: true, position: LegendPosition.bottom),
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
                columnSpacing: 8,
                headingRowColor:
                    WidgetStatePropertyAll(Colors.blueAccent.withOpacity(0.1)),
                sortColumnIndex: [
                  "Date",
                  "Gross",
                  "Net",
                  "Taxes",
                  "Labor Cost",
                  "Order Count",
                  "Tips"
                ].indexOf(_sortColumn),
                sortAscending: _sortAscending,
                columns: [
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 60),
                      child: Text(
                        'Date',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumn = "Date";
                        _sortAscending = ascending;
                      });
                    },
                  ),
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 60),
                      child: Text(
                        'Gross',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumn = "Gross";
                        _sortAscending = ascending;
                      });
                    },
                  ),
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 60),
                      child: Text(
                        'Net',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumn = "Net";
                        _sortAscending = ascending;
                      });
                    },
                  ),
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 60),
                      child: Text(
                        'Taxes',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumn = "Taxes";
                        _sortAscending = ascending;
                      });
                    },
                  ),
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 60),
                      child: Text(
                        'Labor Cost',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumn = "Labor Cost";
                        _sortAscending = ascending;
                      });
                    },
                  ),
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 60),
                      child: Text(
                        'Order Count',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumn = "Order Count";
                        _sortAscending = ascending;
                      });
                    },
                  ),
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 60),
                      child: Text(
                        'Tips',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumn = "Tips";
                        _sortAscending = ascending;
                      });
                    },
                  ),
                ],
                rows: salesData.map((data) {
                  DateTime date = DateTime.parse(data['date']);
                  return DataRow(
                    onSelectChanged: (selected) {
                      if (selected == true) {
                        _showSalesDetailsDialog(data);
                      }
                    },
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 60),
                              child: Text(
                                DateFormat('MMM d').format(date),
                                style: GoogleFonts.poppins(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if ((AuthService.getRole() ?? '').toLowerCase() ==
                                'admin') ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                onPressed: () => _deleteSalesRecord(date),
                              ),
                            ],
                          ],
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 60),
                          child: Text(
                            '\$${data['gross_sales'].toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 60),
                          child: Text(
                            '\$${data['net_sales'].toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 60),
                          child: Text(
                            '\$${data['total_taxes'].toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 60),
                          child: Text(
                            '\$${data['labor_cost'].toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 60),
                          child: Text(
                            data['order_count'].toStringAsFixed(0),
                            style: GoogleFonts.poppins(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 60),
                          child: Text(
                            '\$${data['tips_collected'].toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
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

  void _showSalesDetailsDialog(Map<String, dynamic> data) async {
    DateTime date = DateTime.parse(data['date']);
    String? pdfUrl = data['file'] != null
        ? "$pocketBaseUrl/api/files/daily_sales/${data['id']}/${data['file']}"
        : null;
    String? localPdfPath;

    if (pdfUrl != null) {
      localPdfPath = await _downloadPdf(pdfUrl);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Sales Details - ${DateFormat('MMM d, yyyy').format(date)}',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          content: Container(
            constraints: BoxConstraints(
              minWidth: 300,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Gross Sales',
                      '\$${data['gross_sales'].toStringAsFixed(2)}'),
                  _buildDetailRow(
                      'Net Sales', '\$${data['net_sales'].toStringAsFixed(2)}'),
                  _buildDetailRow('Total Taxes',
                      '\$${data['total_taxes'].toStringAsFixed(2)}'),
                  _buildDetailRow('Labor Cost',
                      '\$${data['labor_cost'].toStringAsFixed(2)}'),
                  _buildDetailRow(
                      'Order Count', data['order_count'].toStringAsFixed(0)),
                  _buildDetailRow(
                      'Labor Hours', data['labor_hours'].toStringAsFixed(2)),
                  _buildDetailRow('Labor Percent',
                      '${data['labor_percent'].toStringAsFixed(2)}%'),
                  _buildDetailRow('Total Discounts',
                      '\$${data['total_discounts'].toStringAsFixed(2)}'),
                  _buildDetailRow(
                      'Voids', '\$${data['voids'].toStringAsFixed(2)}'),
                  _buildDetailRow(
                      'Refunds', '\$${data['refunds'].toStringAsFixed(2)}'),
                  _buildDetailRow('Tips Collected',
                      '\$${data['tips_collected'].toStringAsFixed(2)}'),
                  _buildDetailRow('Cash Sales',
                      '\$${data['cash_sales'].toStringAsFixed(2)}'),
                  _buildDetailRow('Avg Order Value',
                      '\$${data['avg_order_value'].toStringAsFixed(2)}'),
                  _buildDetailRow('Sales per Labor Hour',
                      '\$${data['sales_per_labor_hour'].toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  if (localPdfPath != null) ...[
                    Text(
                      'Uploaded PDF Report',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: SfPdfViewer.file(
                        File(localPdfPath),
                        onDocumentLoadFailed: (details) {
                          _showSnackBar(
                              'Failed to load PDF: ${details.description}',
                              isError: true);
                        },
                      ),
                    ),
                  ] else if (pdfUrl != null) ...[
                    Text(
                      'PDF Preview (Web Fallback)',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PDF preview is not supported on this platform. Please open the link below to view the PDF.',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _showSnackBar('Opening PDF in browser: $pdfUrl',
                            isSuccess: true);
                      },
                      child: Text(
                        'Open PDF',
                        style: GoogleFonts.poppins(color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
