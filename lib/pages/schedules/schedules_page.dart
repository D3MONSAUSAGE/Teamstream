import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teamstream/services/pocketbase/schedules_service.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:intl/intl.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  _SchedulesPageState createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  late final SchedulesService schedulesService;
  List<Map<String, dynamic>> allShifts = [];
  List<Map<String, dynamic>> displayedShifts = [];
  bool isLoading = true;
  DateTime currentWeekStart = DateTime.now()
      .subtract(Duration(days: DateTime.now().weekday - 1))
      .startOfDay(); // Fixed starting point
  int weekOffset = 0; // Offset from current week

  @override
  void initState() {
    super.initState();
    final pb = Provider.of<PocketBase>(context, listen: false);
    schedulesService = SchedulesService(pb);
    _fetchShifts();
  }

  Future<void> _fetchShifts() async {
    setState(() => isLoading = true);
    try {
      final userId = AuthService.getLoggedInUserId();
      print('🔍 Logged-in User ID: $userId');
      if (userId == null) throw Exception('Not logged in');

      allShifts = await schedulesService.fetchShifts(userId: userId);
      print('🔍 All Shifts for User: $allShifts');
      _filterShiftsForWeek();
    } catch (e) {
      print('❌ Fetch Shifts Error: $e');
      _showSnackBar('Error fetching shifts: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterShiftsForWeek() {
    final selectedWeekStart =
        currentWeekStart.add(Duration(days: weekOffset * 7));
    final startOfWeek = DateTime(
        selectedWeekStart.year, selectedWeekStart.month, selectedWeekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 6)).endOfDay();

    displayedShifts = allShifts.where((shift) {
      final shiftStart = DateTime.parse(shift['start_time']).toLocal();
      return shiftStart
              .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          shiftStart.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();

    print(
        '🔍 Displayed Shifts for ${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}: $displayedShifts');
  }

  void _changeWeek(int offset) {
    setState(() {
      weekOffset += offset;
      _filterShiftsForWeek();
    });
  }

  void _resetToCurrentWeek() {
    setState(() {
      weekOffset = 0;
      _filterShiftsForWeek();
    });
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
        currentWeekStart.add(Duration(days: weekOffset * 7));
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'My Schedules',
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
            icon: const Icon(Icons.arrow_back_ios, size: 28),
            onPressed: () => _changeWeek(-1),
            tooltip: 'Previous Week',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 28),
            onPressed: _resetToCurrentWeek,
            tooltip: 'Current Week',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 28),
            onPressed: () => _changeWeek(1),
            tooltip: 'Next Week',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            onPressed: _fetchShifts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Schedule',
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat('MMM d').format(selectedWeekStart)} - '
                      '${DateFormat('MMM d').format(selectedWeekStart.add(const Duration(days: 6)))}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[900],
                      ),
                    ),
                    Text(
                      weekOffset == 0
                          ? 'Current Week'
                          : (weekOffset < 0 ? 'Past Week' : 'Upcoming Week'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: displayedShifts.isEmpty
                    ? Center(
                        child: Text(
                          'No shifts for this week',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final day =
                              selectedWeekStart.add(Duration(days: index));
                          return _buildDayCard(displayedShifts, day);
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(List<Map<String, dynamic>> shifts, DateTime day) {
    final dayShifts = shifts
        .where((s) => DateTime.parse(s['start_time']).toLocal().isSameDay(day))
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            DateFormat('d').format(day),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
          ),
        ),
        title: Text(
          DateFormat('EEEE, MMM d').format(day),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.blue[900],
          ),
        ),
        children: dayShifts.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No shifts scheduled',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ]
            : dayShifts.map((shift) => _buildShiftTile(shift)).toList(),
      ),
    );
  }

  Widget _buildShiftTile(Map<String, dynamic> shift) {
    final start = DateTime.parse(shift['start_time']).toLocal();
    final end = DateTime.parse(shift['end_time']).toLocal();
    final hours = end.difference(start).inMinutes / 60;

    return ListTile(
      title: Text(
        '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.blue[900],
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${hours.toStringAsFixed(1)} hrs',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          if (shift['notes'] != null && shift['notes'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                shift['notes'],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
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
