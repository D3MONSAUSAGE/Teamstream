import 'package:flutter/material.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/services/pocketbase_service.dart';
import 'package:intl/intl.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  RequestsPageState createState() => RequestsPageState();
}

class RequestsPageState extends State<RequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text("Employee Requests"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "New Request"),
            Tab(text: "My Requests"),
            Tab(text: "Request History"),
          ],
        ),
      ),
      drawer: const MenuDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          NewRequestTab(),
          MyRequestsTab(),
          RequestHistoryTab(),
        ],
      ),
    );
  }
}

// --------------------------------------------
// 🔹 NEW REQUEST FORM TAB
// --------------------------------------------
class NewRequestTab extends StatefulWidget {
  @override
  _NewRequestTabState createState() => _NewRequestTabState();
}

class _NewRequestTabState extends State<NewRequestTab> {
  final TextEditingController reasonController = TextEditingController();
  DateTime? selectedDate;
  String selectedRequestType = "Leave Request"; // Default selection
  bool isSubmitting = false;

  void submitRequest() async {
    if (selectedDate == null || reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill out all fields.")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    await PocketBaseService.submitRequest(
      requestType: selectedRequestType,
      reason: reasonController.text,
      date: selectedDate!,
    );

    setState(() => isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request submitted successfully!")),
    );

    reasonController.clear();
    setState(() => selectedDate = null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Request Type",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: selectedRequestType,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                  value: "Leave Request", child: Text("Leave Request")),
              DropdownMenuItem(
                  value: "Shift Change", child: Text("Shift Change")),
              DropdownMenuItem(value: "HR Request", child: Text("HR Request")),
            ],
            onChanged: (value) {
              setState(() => selectedRequestType = value!);
            },
          ),
          const SizedBox(height: 10),
          const Text("Request Date",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            title: Text(selectedDate == null
                ? "Select a date"
                : DateFormat.yMMMd().format(selectedDate!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(DateTime.now().year + 1),
              );
              if (pickedDate != null) {
                setState(() => selectedDate = pickedDate);
              }
            },
          ),
          const SizedBox(height: 10),
          const Text("Reason for Request",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
            controller: reasonController,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: "Enter details...",
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isSubmitting ? null : submitRequest,
            child: isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Submit Request"),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------
// 🔹 MY REQUESTS TAB
// --------------------------------------------
class MyRequestsTab extends StatefulWidget {
  @override
  _MyRequestsTabState createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<MyRequestsTab> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  void loadRequests() async {
    List<Map<String, dynamic>> fetchedRequests =
        await PocketBaseService.fetchMyRequests();
    setState(() {
      requests = fetchedRequests;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : requests.isEmpty
            ? const Center(child: Text("No active requests."))
            : ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(request['request_type']),
                      subtitle: Text("Status: ${request['status']}"),
                      trailing: Icon(
                        request['status'] == "Pending"
                            ? Icons.hourglass_empty
                            : request['status'] == "Approved"
                                ? Icons.check_circle
                                : Icons.cancel,
                        color: request['status'] == "Approved"
                            ? Colors.green
                            : request['status'] == "Rejected"
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                  );
                },
              );
  }
}

// --------------------------------------------
// 🔹 REQUEST HISTORY TAB
// --------------------------------------------
class RequestHistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("View past approved and rejected requests here."),
    );
  }
}
