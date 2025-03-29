import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';
import 'package:teamstream/services/pocketbase/clock_in_service.dart';
import 'package:teamstream/utils/constants.dart';

class TimecardsReportPage extends StatefulWidget {
  const TimecardsReportPage({super.key});

  @override
  State<TimecardsReportPage> createState() => _TimecardsReportPageState();
}

class _TimecardsReportPageState extends State<TimecardsReportPage> {
  List<dynamic> _clockIns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClockIns();
  }

  Future<void> _fetchClockIns() async {
    try {
      final userId = AuthService.getLoggedInUserId();

      if (userId == null) {
        throw Exception("User not logged in");
      }

      // Fetch clock-ins from PocketBase using fetchList instead of fetchAll
      final result = await BaseService.fetchList(
        ClockInService.clockInsCollection,
        filter: 'user = "$userId"',
        sort: '-created',
      );

      setState(() {
        _clockIns = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to fetch clock-ins: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper function to format DateTime
  String _formatDateTime(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Clock-Ins Report",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clockIns.isEmpty
              ? Center(
                  child: Text(
                    "No clock-ins found.",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _clockIns.length,
                  itemBuilder: (context, index) {
                    final clockIn = _clockIns[index];
                    final time = _formatDateTime(clockIn['time']);
                    final latitude = clockIn['latitude'];
                    final longitude = clockIn['longitude'];
                    final code = clockIn['code'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          "Clock-In #${index + 1}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          "Time: $time\nLocation: ($latitude, $longitude)\nCode: $code",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        onTap: () {
                          // Navigate to a detailed view or edit page if needed
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchClockIns,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
