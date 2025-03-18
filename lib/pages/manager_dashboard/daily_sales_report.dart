import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamstream/services/pocketbase/daily_sales_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:intl/intl.dart'; // For date formatting

class DailySalesReportPage extends StatefulWidget {
  const DailySalesReportPage({super.key});

  @override
  _DailySalesReportPageState createState() => _DailySalesReportPageState();
}

class _DailySalesReportPageState extends State<DailySalesReportPage> {
  List<Map<String, dynamic>> salesData = [];
  List<Map<String, dynamic>> filteredSalesData = [];
  bool isLoading = true;
  DateTimeRange? selectedDateRange;
  double totalGrossSales = 0.0;
  double totalNetSales = 0.0;
  double totalTaxes = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchSalesData();
  }

  Future<void> _fetchSalesData() async {
    setState(() => isLoading = true);
    try {
      final data = await DailySalesService.fetchDailySales();
      if (mounted) {
        setState(() {
          salesData = data;
          _filterAndCalculateTotals();
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching daily sales data: $e");
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar('Error fetching sales data: $e', isError: true);
      }
    }
  }

  void _filterAndCalculateTotals() {
    if (selectedDateRange == null) {
      filteredSalesData = List.from(salesData);
    } else {
      filteredSalesData = salesData.where((sale) {
        final saleDate =
            DateTime.tryParse(sale['date'] ?? '') ?? DateTime.now();
        return saleDate.isAfter(
                selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            saleDate
                .isBefore(selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    totalGrossSales = filteredSalesData.fold(
        0.0, (sum, sale) => sum + (sale['gross_sales'] as double? ?? 0.0));
    totalNetSales = filteredSalesData.fold(
        0.0, (sum, sale) => sum + (sale['net_sales'] as double? ?? 0.0));
    totalTaxes = filteredSalesData.fold(
        0.0, (sum, sale) => sum + (sale['total_taxes'] as double? ?? 0.0));
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

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blueAccent,
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
        _filterAndCalculateTotals();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Match ManagerDashboardPage
      appBar: AppBar(
        title: Text(
          'Daily Sales Report',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, size: 28),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Filter by Date',
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 28),
            onPressed: () {
              _showSnackBar('Exporting report... (Coming soon)');
              // TODO: Implement export functionality (e.g., CSV)
            },
            tooltip: 'Export Report',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            12, 24, 12, 16), // Match ManagerDashboardPage
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Overview',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent))
            else if (salesData.isEmpty)
              Center(
                child: Text(
                  '⚠️ No sales data available.',
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey[600]),
                ),
              )
            else ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary${selectedDateRange != null ? " (${DateFormat.yMMMd().format(selectedDateRange!.start)} - ${DateFormat.yMMMd().format(selectedDateRange!.end)})" : ""}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem('Gross Sales',
                            '\$${totalGrossSales.toStringAsFixed(2)}'),
                        _buildSummaryItem('Net Sales',
                            '\$${totalNetSales.toStringAsFixed(2)}'),
                        _buildSummaryItem(
                            'Taxes', '\$${totalTaxes.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredSalesData.length,
                  padding: const EdgeInsets.only(bottom: 6),
                  itemBuilder: (context, index) {
                    final sale = filteredSalesData[index];
                    final date =
                        DateTime.tryParse(sale['date'] ?? '') ?? DateTime.now();
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.attach_money,
                              color: Colors.white, size: 24),
                        ),
                        title: Text(
                          "📅 ${DateFormat.yMMMd().format(date)}",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[900],
                          ),
                        ),
                        subtitle: Text(
                          "💰 Gross: \$${sale['gross_sales'] ?? '0.00'}\n"
                          "💵 Net: \$${sale['net_sales'] ?? '0.00'}\n"
                          "💲 Taxes: \$${sale['total_taxes'] ?? '0.00'}",
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.grey[700]),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: Colors.blueAccent, size: 20),
                        onTap: () {
                          _showSnackBar(
                              'Detailed view for ${DateFormat.yMMMd().format(date)} coming soon!');
                          // TODO: Navigate to detailed sales view
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchSalesData,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.blue[900],
          ),
        ),
      ],
    );
  }
}
