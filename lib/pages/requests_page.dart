import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/services/pocketbase_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  RequestsPageState createState() => RequestsPageState();
}

class RequestsPageState extends State<RequestsPage> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    setState(() => isLoading = true);
    try {
      List<Map<String, dynamic>> fetchedRequests =
          await PocketBaseService.fetchRequests();
      setState(() {
        requests = fetchedRequests;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading requests: $e");
      _showSnackBar('Error loading requests: $e', isError: true);
      setState(() => isLoading = false);
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
          'My Requests',
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
          : requests.isEmpty
              ? Center(
                  child: Text(
                    'No requests found.',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    var request = requests[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(
                          request["request_type"],
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Status: ${request["status"]}",
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.grey[700]),
                            ),
                            Text(
                              "Urgency: ${request["urgency"]}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: request["urgency"] == "High"
                                    ? Colors.red
                                    : request["urgency"] == "Medium"
                                        ? Colors.orange
                                        : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        trailing:
                            const Icon(Icons.info, color: Colors.blueAccent),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRequestDialog(context),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddRequestDialog(BuildContext context) {
    TextEditingController descriptionController = TextEditingController();
    String selectedRequestType = "Time Off";
    String selectedUrgency = "Medium";
    DateTime? selectedDate;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;
    bool isTimeOpen = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Submit a Request",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRequestType,
                      items: [
                        "Time Off",
                        "Expense",
                        "Meeting",
                        "Shift Change",
                        "Sick Time",
                        "Vacations"
                      ]
                          .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: GoogleFonts.poppins())))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedRequestType = value!);
                      },
                      decoration: InputDecoration(
                        labelText: "Request Type",
                        labelStyle:
                            GoogleFonts.poppins(color: Colors.grey[700]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Colors.blueAccent),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedUrgency,
                      items: ["Low", "Medium", "High"]
                          .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level, style: GoogleFonts.poppins())))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedUrgency = value!);
                      },
                      decoration: InputDecoration(
                        labelText: "Urgency Level",
                        labelStyle:
                            GoogleFonts.poppins(color: Colors.grey[700]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Colors.blueAccent),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: "Reason",
                        labelStyle:
                            GoogleFonts.poppins(color: Colors.grey[700]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Colors.blueAccent),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    if (selectedRequestType == "Meeting") ...[
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: Text("Leave meeting time open",
                            style: GoogleFonts.poppins()),
                        value: isTimeOpen,
                        onChanged: (bool? value) {
                          setState(() {
                            isTimeOpen = value ?? false;
                            if (isTimeOpen) {
                              selectedDate = null;
                              selectedStartTime = null;
                              selectedEndTime = null;
                            }
                          });
                        },
                        activeColor: Colors.blueAccent,
                      ),
                      if (!isTimeOpen) ...[
                        ListTile(
                          title: Text(
                            selectedDate == null
                                ? "Select Meeting Date"
                                : "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}",
                            style: GoogleFonts.poppins(),
                          ),
                          leading: const Icon(Icons.calendar_today,
                              color: Colors.blueAccent),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setState(() => selectedDate = pickedDate);
                            }
                          },
                        ),
                        ListTile(
                          title: Text(
                            selectedStartTime == null
                                ? "Select Start Time"
                                : "Start Time: ${selectedStartTime!.format(context)}",
                            style: GoogleFonts.poppins(),
                          ),
                          leading: const Icon(Icons.access_time,
                              color: Colors.blueAccent),
                          onTap: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() => selectedStartTime = pickedTime);
                            }
                          },
                        ),
                        ListTile(
                          title: Text(
                            selectedEndTime == null
                                ? "Select End Time"
                                : "End Time: ${selectedEndTime!.format(context)}",
                            style: GoogleFonts.poppins(),
                          ),
                          leading: const Icon(Icons.access_time,
                              color: Colors.blueAccent),
                          onTap: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() => selectedEndTime = pickedTime);
                            }
                          },
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await PocketBaseService.submitRequest(
                          requestType: selectedRequestType,
                          description: descriptionController.text.trim(),
                          urgency: selectedUrgency,
                          isRecurring: false, // Hardcoded to false
                          recurringType: null, // No recurring type
                          meetingDate: isTimeOpen ? null : selectedDate,
                          meetingStart: isTimeOpen ? null : selectedStartTime,
                          meetingEnd: isTimeOpen ? null : selectedEndTime,
                        );
                        _showSnackBar('Request submitted successfully!',
                            isSuccess: true);
                        loadRequests();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                      ),
                      child: Text(
                        "Submit Request",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
