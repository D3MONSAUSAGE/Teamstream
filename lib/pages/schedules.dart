import 'package:flutter/material.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/services/pocketbase_service.dart';
import 'package:intl/intl.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  SchedulesPageState createState() => SchedulesPageState();
}

class SchedulesPageState extends State<SchedulesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Schedules"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Assigned"),
            Tab(text: "Upcoming"),
            Tab(text: "Past"),
            Tab(text: "Shift Drops"),
          ],
        ),
      ),
      drawer: const MenuDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          AssignedSchedulesTab(),
          UpcomingSchedulesTab(),
          PastSchedulesTab(),
          ShiftDropRequestsTab(),
        ],
      ),
    );
  }
}

/// 🔹 Assigned Schedules Tab
class AssignedSchedulesTab extends StatefulWidget {
  @override
  _AssignedSchedulesTabState createState() => _AssignedSchedulesTabState();
}

class _AssignedSchedulesTabState extends State<AssignedSchedulesTab> {
  List<Map<String, dynamic>> assignedShifts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAssignedSchedules();
  }

  void loadAssignedSchedules() async {
    List<Map<String, dynamic>> fetchedShifts =
        await PocketBaseService.fetchAssignedSchedules();
    setState(() {
      assignedShifts = fetchedShifts;
      isLoading = false;
    });
  }

  double calculateTotalHours() {
    return assignedShifts.fold(
        0, (sum, shift) => sum + (shift['total_hours'] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Assigned Shifts",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Total Hours Assigned: ${calculateTotalHours().toStringAsFixed(1)} hrs",
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blueAccent),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : assignedShifts.isEmpty
                    ? const Center(child: Text("No assigned shifts."))
                    : ListView.builder(
                        itemCount: assignedShifts.length,
                        itemBuilder: (context, index) {
                          final shift = assignedShifts[index];
                          String shiftDate = DateFormat.yMMMd()
                              .format(DateTime.parse(shift['date']));

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            child: ListTile(
                              title: Text("${shift['position']}"),
                              subtitle: Text(
                                  "$shiftDate • ${shift['start_time']} - ${shift['end_time']}"),
                              trailing: Text(
                                shift['status'],
                                style: TextStyle(
                                  color: shift['status'] == "Upcoming"
                                      ? Colors.blue
                                      : shift['status'] == "Active"
                                          ? Colors.green
                                          : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 Upcoming Schedules Tab
class UpcomingSchedulesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("View your upcoming schedules here."),
    );
  }
}

/// 🔹 Past Schedules Tab
class PastSchedulesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("View past schedules and hours worked."),
    );
  }
}

/// 🔹 Shift Drop Requests Tab
class ShiftDropRequestsTab extends StatefulWidget {
  @override
  _ShiftDropRequestsTabState createState() => _ShiftDropRequestsTabState();
}

class _ShiftDropRequestsTabState extends State<ShiftDropRequestsTab> {
  List<Map<String, dynamic>> shiftDrops = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadShiftDropRequests();
  }

  void loadShiftDropRequests() async {
    List<Map<String, dynamic>> fetchedShifts =
        await PocketBaseService.fetchShiftDropRequests();
    setState(() {
      shiftDrops = fetchedShifts;
      isLoading = false;
    });
  }

  void claimShift(String shiftId) async {
    await PocketBaseService.claimShift(shiftId);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shift claimed successfully!")),
    );
    loadShiftDropRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Available Shift Drops",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : shiftDrops.isEmpty
                    ? const Center(child: Text("No available shift drops."))
                    : ListView.builder(
                        itemCount: shiftDrops.length,
                        itemBuilder: (context, index) {
                          final shift = shiftDrops[index];
                          String shiftDate = DateFormat.yMMMd()
                              .format(DateTime.parse(shift['date']));

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            child: ListTile(
                              title: Text("${shift['position']}"),
                              subtitle: Text(
                                  "$shiftDate • ${shift['start_time']} - ${shift['end_time']}"),
                              trailing: ElevatedButton(
                                onPressed: () => claimShift(shift['id']),
                                child: const Text("Claim Shift"),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
