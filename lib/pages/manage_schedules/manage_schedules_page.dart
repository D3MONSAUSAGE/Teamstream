import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teamstream/services/pocketbase/schedules_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:intl/intl.dart';
import 'add_shift_dialog.dart'; // Import the new dialog
import 'employee_schedule_card.dart'; // Import the new card widget

class ManageSchedulesPage extends StatefulWidget {
  const ManageSchedulesPage({super.key});

  @override
  State<ManageSchedulesPage> createState() => _ManageSchedulesPageState();
}

class _ManageSchedulesPageState extends State<ManageSchedulesPage> {
  late final SchedulesService _schedulesService;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _allShifts = [];
  List<Map<String, dynamic>> _filteredShifts = [];
  bool _isLoading = true;
  int _weekOffset = 0;
  DateTime _currentWeekStart = DateTime.now()
      .subtract(Duration(days: DateTime.now().weekday - 1))
      .startOfDay();
  String? _selectedShiftType;
  String _searchQuery = '';
  final List<String> _shiftTypes = [
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
    'Custom'
  ];

  @override
  void initState() {
    super.initState();
    final pb = Provider.of<PocketBase>(context, listen: false);
    _schedulesService = SchedulesService(pb);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _schedulesService.fetchEmployees(),
        _schedulesService.fetchShifts(),
      ]);
      _employees = results[0];
      _allShifts = results[1];
      _filterShiftsForWeek();
    } catch (e) {
      _showSnackBar('Error fetching data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterShiftsForWeek() {
    final selectedWeekStart =
        _currentWeekStart.add(Duration(days: _weekOffset * 7));
    final startOfWeek = DateTime(
        selectedWeekStart.year, selectedWeekStart.month, selectedWeekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 6)).endOfDay();

    _filteredShifts = _allShifts.where((shift) {
      final shiftStart = DateTime.parse(shift['start_time']).toLocal();
      final isInWeek =
          shiftStart.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              shiftStart.isBefore(endOfWeek.add(const Duration(days: 1)));
      final matchesShiftType = _selectedShiftType == null ||
          _getShiftType(shift) == _selectedShiftType;
      return isInWeek && matchesShiftType;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      _filteredShifts = _filteredShifts.where((shift) {
        final employee = _employees.firstWhere((e) => e['id'] == shift['user'],
            orElse: () => {'name': ''});
        return (employee['name'] as String)
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  String _getShiftType(Map<String, dynamic> shift) {
    final start = DateTime.parse(shift['start_time']).toLocal();
    final hour = start.hour;
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 22) return 'Evening';
    if (hour >= 22 || hour < 5) return 'Night';
    return 'Custom';
  }

  void _changeWeek(int offset) {
    setState(() {
      _weekOffset += offset;
      _filterShiftsForWeek();
    });
  }

  void _resetToCurrentWeek() {
    setState(() {
      _weekOffset = 0;
      _filterShiftsForWeek();
    });
  }

  Future<void> _addShift({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      await _schedulesService.createShift(
        userId: userId,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
      );
      await _fetchData();
      _showSnackBar('Shift added successfully', isSuccess: true);
    } catch (e) {
      _showSnackBar('Error adding shift: $e', isError: true);
    }
  }

  Future<void> _deleteShift(String shiftId) async {
    try {
      await _schedulesService.deleteShift(shiftId);
      setState(() => _allShifts.removeWhere((s) => s['id'] == shiftId));
      _filterShiftsForWeek();
      _showSnackBar('Shift deleted successfully', isSuccess: true);
    } catch (e) {
      _showSnackBar('Error deleting shift: $e', isError: true);
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

  @override
  Widget build(BuildContext context) {
    final selectedWeekStart =
        _currentWeekStart.add(Duration(days: _weekOffset * 7));
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Manage Schedules',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, size: 24),
            onPressed: () =>
                _showSnackBar('Exporting schedules... (Coming soon)'),
            tooltip: 'Export Schedules',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: _fetchData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: Column(
        children: [
          _buildWeekNavigationBar(selectedWeekStart),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Expanded(
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.blueAccent)),
                    )
                  else
                    Expanded(
                      child: _buildScheduleList(selectedWeekStart),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddShiftDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildWeekNavigationBar(DateTime monday) {
    return Container(
      color: Colors.blueAccent.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, size: 24, color: Colors.white),
            onPressed: () => _changeWeek(-1),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d, yyyy').format(monday.add(const Duration(days: 6)))}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today,
                    size: 24, color: Colors.white),
                onPressed: _resetToCurrentWeek,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    size: 24, color: Colors.white),
                onPressed: () => _changeWeek(1),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                hintText: 'Search Employees',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterShiftsForWeek();
                });
              },
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _selectedShiftType,
              decoration: InputDecoration(
                hintText: 'Shift Type',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
              items: [
                const DropdownMenuItem(
                    value: null,
                    child: Text('All',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14))),
                ..._shiftTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type,
                        style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 14)))),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedShiftType = value;
                  _filterShiftsForWeek();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(DateTime monday) {
    final filteredEmployees = _employees
        .where((e) => _filteredShifts.any((s) => s['user'] == e['id']))
        .toList();
    if (filteredEmployees.isEmpty) {
      return Center(
        child: Text(
          'No schedules found for this week',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = filteredEmployees[index];
        final employeeShifts =
            _filteredShifts.where((s) => s['user'] == employee['id']).toList();
        return EmployeeScheduleCard(
          employee: employee,
          monday: monday,
          employeeShifts: employeeShifts,
          onDeleteShift: _deleteShift,
          onShowShiftDetails: _showShiftDetails,
        );
      },
    );
  }

  void _showShiftDetails(Map<String, dynamic> shift) {
    final start = DateTime.parse(shift['start_time']).toLocal();
    final end = DateTime.parse(shift['end_time']).toLocal();
    final employee = _employees.firstWhere((e) => e['id'] == shift['user'],
        orElse: () => {'name': 'Unknown'});
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Shift Details',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.blue[900]),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${employee['name']}',
                style: GoogleFonts.poppins(fontSize: 14)),
            Text('Date: ${DateFormat('MMM d, yyyy').format(start)}',
                style: GoogleFonts.poppins(fontSize: 14)),
            Text(
                'Time: ${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}',
                style: GoogleFonts.poppins(fontSize: 14)),
            if (shift['notes'] != null && shift['notes'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Notes: ${shift['notes']}',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontStyle: FontStyle.italic)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.poppins(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  void _showAddShiftDialog() {
    showDialog(
      context: context,
      builder: (_) => AddShiftDialog(
        employees: _employees,
        onAddShift: _addShift,
      ),
    );
  }
}

extension DateTimeExt on DateTime {
  DateTime startOfDay() => DateTime(year, month, day);
  DateTime endOfDay() => DateTime(year, month, day, 23, 59, 59);
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
