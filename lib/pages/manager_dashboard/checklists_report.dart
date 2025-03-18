import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart'; // Adjust path as needed

class ChecklistsReportPage extends StatefulWidget {
  const ChecklistsReportPage({super.key});

  @override
  _ChecklistsReportPageState createState() => _ChecklistsReportPageState();
}

class _ChecklistsReportPageState extends State<ChecklistsReportPage> {
  List<Map<String, dynamic>> _checklists = [];
  bool _isLoading = true;
  String _selectedBranch = "All";
  String _selectedArea = "All";
  String _selectedShift = "All";
  DateTimeRange? _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  ); // Default to last 7 days

  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  Future<void> _loadChecklists() async {
    setState(() => _isLoading = true);
    try {
      final fetchedChecklists = await ChecklistsService.fetchChecklists();
      if (mounted) {
        setState(() {
          _checklists = fetchedChecklists;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error loading checklists: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error loading checklists: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredChecklists {
    return _checklists.where((checklist) {
      final branchMatch =
          _selectedBranch == "All" || checklist["branch"] == _selectedBranch;
      final areaMatch =
          _selectedArea == "All" || checklist["area"] == _selectedArea;
      final shiftMatch =
          _selectedShift == "All" || checklist["shift"] == _selectedShift;
      final dateMatch = _selectedDateRange == null ||
          (DateTime.parse(checklist["start_time"])
                  .isAfter(_selectedDateRange!.start) &&
              DateTime.parse(checklist["start_time"]).isBefore(
                  _selectedDateRange!.end.add(const Duration(days: 1))));
      return branchMatch && areaMatch && shiftMatch && dateMatch;
    }).toList();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Checklist Dashboard",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(),
                  _buildTrendLineChart(),
                  _buildScorePieChart(),
                  _buildChecklistList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    final executedCount =
        _filteredChecklists.where((c) => c["completed"] == true).length;
    final verifiedCount = _filteredChecklists
        .where((c) => c["verified_by_manager"] == true)
        .length;
    final totalCount = _filteredChecklists.length;
    final executionPercentage = totalCount > 0
        ? (executedCount / totalCount * 100).toStringAsFixed(1)
        : "0.0";
    final verificationPercentage = totalCount > 0
        ? (verifiedCount / totalCount * 100).toStringAsFixed(1)
        : "0.0";

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCard("Total", "$totalCount", Colors.blueAccent),
          _buildSummaryCard("Executed", "$executionPercentage%", Colors.green),
          _buildSummaryCard(
              "Verified", "$verificationPercentage%", Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title,
              style:
                  GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTrendLineChart() {
    if (_selectedDateRange == null) return const SizedBox.shrink();

    final days =
        _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays +
            1;
    final List<FlSpot> executionSpots = [];
    final List<FlSpot> verificationSpots = [];

    for (int i = 0; i < days; i++) {
      final date = _selectedDateRange!.start.add(Duration(days: i));
      final dailyChecklists = _filteredChecklists.where((c) {
        final checklistDate = DateTime.parse(c["start_time"]);
        return checklistDate.day == date.day &&
            checklistDate.month == date.month &&
            checklistDate.year == date.year;
      }).toList();
      final total = dailyChecklists.length;
      final executed =
          dailyChecklists.where((c) => c["completed"] == true).length;
      final verified =
          dailyChecklists.where((c) => c["verified_by_manager"] == true).length;

      final executionPercentage = total > 0 ? (executed / total) * 100 : 0;
      final verificationPercentage = total > 0 ? (verified / total) * 100 : 0;

      // Clamp values to ensure they stay between 0 and 100
      final clampedExecution = executionPercentage.clamp(0.0, 100.0);
      final clampedVerification = verificationPercentage.clamp(0.0, 100.0);

      executionSpots.add(FlSpot(i.toDouble(), clampedExecution.toDouble()));
      verificationSpots
          .add(FlSpot(i.toDouble(), clampedVerification.toDouble()));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Execution & Verification Trends",
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                clipData: FlClipData(
                    bottom: true, top: true, left: true, right: true),
                gridData: FlGridData(show: true, horizontalInterval: 25),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: days > 10 ? 2 : 1,
                      getTitlesWidget: (value, meta) {
                        final date = _selectedDateRange!.start
                            .add(Duration(days: value.toInt()));
                        return Text(DateFormat('MM/dd').format(date),
                            style: GoogleFonts.poppins(fontSize: 12));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                            "${value.toInt()}%",
                            style: GoogleFonts.poppins(fontSize: 12))),
                  ),
                ),
                borderData: FlBorderData(show: true),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: executionSpots,
                    isCurved: true,
                    curveSmoothness: 0.2, // Reduce dipping
                    color: Colors.green,
                    dotData: FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: verificationSpots,
                    isCurved: true,
                    curveSmoothness: 0.2, // Reduce dipping
                    color: Colors.blue,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend("Execution", Colors.green),
              const SizedBox(width: 16),
              _buildLegend("Verification", Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }

  Widget _buildScorePieChart() {
    final total = _filteredChecklists.length;
    final executed =
        _filteredChecklists.where((c) => c["completed"] == true).length;
    final verified = _filteredChecklists
        .where((c) => c["verified_by_manager"] == true)
        .length;
    final incomplete = total - executed;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Overall Scores",
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                      value: executed.toDouble(),
                      color: Colors.green,
                      title: "Executed\n$executed",
                      radius: 50,
                      titleStyle: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white)),
                  PieChartSectionData(
                      value: verified.toDouble(),
                      color: Colors.blue,
                      title: "Verified\n$verified",
                      radius: 50,
                      titleStyle: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white)),
                  PieChartSectionData(
                      value: incomplete.toDouble(),
                      color: Colors.grey,
                      title: "Incomplete\n$incomplete",
                      radius: 50,
                      titleStyle: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white)),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Checklist Details",
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._filteredChecklists
              .map((checklist) => _buildChecklistCard(checklist))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(Map<String, dynamic> checklist) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              checklist["completed"] == true
                  ? Icons.check_circle
                  : Icons.cancel,
              color: checklist["completed"] == true ? Colors.green : Colors.red,
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checklist["title"] ?? "Untitled",
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${checklist["branch"] ?? 'N/A'} • ${checklist["area"] ?? 'N/A'} • ${checklist["shift"] ?? 'N/A'}",
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    DateFormat('MM/dd/yyyy')
                        .format(DateTime.parse(checklist["start_time"])),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(
              checklist["verified_by_manager"] == true
                  ? Icons.verified
                  : Icons.pending,
              color: checklist["verified_by_manager"] == true
                  ? Colors.green
                  : Colors.orange,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Filters",
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedBranch,
                    items: ["All", "Canyon", "Sylmar CA", "Via Princess CA"]
                        .map((branch) => DropdownMenuItem(
                            value: branch, child: Text(branch)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() => _selectedBranch = value!);
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                        labelText: "Branch", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedArea,
                    items: ["All", "Kitchen"]
                        .map((area) =>
                            DropdownMenuItem(value: area, child: Text(area)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() => _selectedArea = value!);
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                        labelText: "Area", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedShift,
                    items: [
                      "All",
                      "13:00 +1",
                      "12:30 +1",
                      "0:00 +1",
                      "14:00 +1",
                      "15:00"
                    ]
                        .map((shift) =>
                            DropdownMenuItem(value: shift, child: Text(shift)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() => _selectedShift = value!);
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                        labelText: "Shift", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent),
                    child: Text(
                      _selectedDateRange == null
                          ? "Select Date Range"
                          : "Date: ${DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd').format(_selectedDateRange!.end)}",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

void main() => runApp(const MaterialApp(home: ChecklistsReportPage()));
