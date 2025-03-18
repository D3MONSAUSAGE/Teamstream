import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/expense_service.dart';
import 'package:teamstream/services/pocketbase/invoice_service.dart';
import 'package:teamstream/services/pocketbase/schedules_service.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  late SchedulesService schedulesService;
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> schedules = [];
  List<Map<String, dynamic>> checklists = [];
  bool isLoading = true;
  double totalExpenses = 0.0;
  double totalInvoices = 0.0;
  int pendingInvoices = 0;

  @override
  void initState() {
    super.initState();
    final pb = PocketBase(
        'http://your-pocketbase-url'); // Replace with your actual URL
    schedulesService = SchedulesService(pb);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      expenses = await ExpenseService.fetchExpenses();
      invoices = await InvoiceService.fetchInvoices();
      String? userId = AuthService.getLoggedInUserId();
      if (userId != null) {
        DateTime now = DateTime.now();
        DateTime tomorrowStart = DateTime(now.year, now.month, now.day + 1);
        DateTime tomorrowEnd = tomorrowStart.add(const Duration(days: 1));
        schedules = await schedulesService.fetchShifts(
          userId: userId,
          start: tomorrowStart,
          end: tomorrowEnd,
        );
      }
      checklists = await ChecklistsService.fetchChecklists();

      totalExpenses =
          expenses.fold(0.0, (sum, e) => sum + (e["amount"] as num? ?? 0));
      totalInvoices =
          invoices.fold(0.0, (sum, i) => sum + (i["amount"] as num? ?? 0));
      pendingInvoices = invoices.where((i) => i["status"] == "Pending").length;

      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      _showSnackBar('Error loading dashboard data: $e', isError: true);
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor:
            isSuccess ? Colors.green : (isError ? Colors.red : null),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Dashboard',
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
              // Placeholder for notifications action
              _showSnackBar('Notifications clicked - functionality TBD');
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your TeamStream overview.',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  _buildQuickStats(),
                  const SizedBox(height: 20),
                  _buildScheduleSection(),
                  const SizedBox(height: 20),
                  _buildChecklistPerformance(),
                  const SizedBox(height: 20),
                  _buildFinancialBarChart(),
                  const SizedBox(height: 20),
                  _buildExpenseTrendChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Expenses',
                    '\$${totalExpenses.toStringAsFixed(2)}', Colors.red),
                _buildStatItem('Total Invoices',
                    '\$${totalInvoices.toStringAsFixed(2)}', Colors.green),
                _buildStatItem('Pending Invoices', pendingInvoices.toString(),
                    Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    List<Map<String, dynamic>> tomorrowSchedules = schedules;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tomorrow’s Schedule (${DateFormat('MMM d, yyyy').format(tomorrow)})',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            tomorrowSchedules.isEmpty
                ? Text(
                    'No shifts scheduled for tomorrow.',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[600]),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tomorrowSchedules.length,
                    itemBuilder: (context, index) {
                      var schedule = tomorrowSchedules[index];
                      DateTime startTime =
                          DateTime.parse(schedule["start_time"]);
                      DateTime endTime = DateTime.parse(schedule["end_time"]);
                      String timeRange =
                          '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';
                      return ListTile(
                        leading:
                            const Icon(Icons.event, color: Colors.blueAccent),
                        title: Text(
                          schedule["user"] != null
                              ? (schedule["expand"]?["user"]?["name"] ??
                                  "Unnamed User")
                              : "Shift",
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '$timeRange${schedule["notes"] != null && schedule["notes"].isNotEmpty ? " - ${schedule["notes"]}" : ""}',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[700]),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistPerformance() {
    Map<String, Map<String, int>> areaStats = {};
    for (var checklist in checklists) {
      String area = checklist["area"] ?? "Unknown";
      if (!areaStats.containsKey(area)) {
        areaStats[area] = {"completed": 0, "total": 0};
      }
      areaStats[area]!["total"] = areaStats[area]!["total"]! + 1;
      if (checklist["completed"] == true) {
        areaStats[area]!["completed"] = areaStats[area]!["completed"]! + 1;
      }
    }

    Map<String, double> areaPerformance = {};
    areaStats.forEach((area, stats) {
      areaPerformance[area] = stats["total"]! > 0
          ? (stats["completed"]! / stats["total"]!) * 100
          : 0;
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Area Checklist Performance',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            areaPerformance.isEmpty
                ? Text(
                    'No checklist data available.',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[600]),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: areaPerformance.length,
                    itemBuilder: (context, index) {
                      String area = areaPerformance.keys.elementAt(index);
                      double percentage = areaPerformance[area]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                area,
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentage >= 80
                                      ? Colors.green
                                      : percentage >= 50
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialBarChart() {
    double maxY =
        (totalExpenses > totalInvoices ? totalExpenses : totalInvoices) * 1.2;
    double gridInterval = totalExpenses > 0
        ? totalExpenses / 5
        : maxY > 0
            ? maxY / 5
            : 100.0;

    return _buildCard(
      title: 'Expenses vs Invoices',
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: gridInterval,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(fontSize: 12);
                  return value == 1
                      ? const Text('Expenses', style: style)
                      : const Text('Invoices', style: style);
                },
              ),
            ),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: [
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                  toY: totalExpenses, color: Colors.redAccent, width: 16),
            ]),
            BarChartGroupData(x: 2, barRods: [
              BarChartRodData(
                  toY: totalInvoices, color: Colors.green, width: 16),
            ]),
          ],
          maxY: maxY > 0 ? maxY : 100.0,
        ),
      ),
    );
  }

  Widget _buildExpenseTrendChart() {
    Map<String, double> monthlyExpenses = {};
    for (var expense in expenses) {
      String month =
          DateFormat('MMM yyyy').format(DateTime.parse(expense["date"]));
      monthlyExpenses[month] =
          (monthlyExpenses[month] ?? 0) + (expense["amount"] as num? ?? 0);
    }

    List<FlSpot> spots = [];
    List<String> months = monthlyExpenses.keys.toList()..sort();
    for (int i = 0; i < months.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyExpenses[months[i]]!));
    }

    return _buildCard(
      title: 'Monthly Expense Trend',
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          borderData: FlBorderData(
              show: true, border: Border.all(color: Colors.grey[300]!)),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < months.length) {
                    return Text(months[index].split(' ')[0],
                        style: GoogleFonts.poppins(fontSize: 12));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 4,
              color: Colors.blueAccent,
              belowBarData: BarAreaData(
                  show: true, color: Colors.blueAccent.withOpacity(0.1)),
            ),
          ],
          maxY: monthlyExpenses.values.isEmpty
              ? 100
              : monthlyExpenses.values.reduce((a, b) => a > b ? a : b) * 1.2,
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }
}
