import 'package:flutter/material.dart';
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

  void loadRequests() async {
    try {
      List<Map<String, dynamic>> fetchedRequests =
          await PocketBaseService.fetchRequests();
      setState(() {
        requests = fetchedRequests;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading requests: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ADD THIS METHOD
    return Scaffold(
      appBar: AppBar(title: const Text("My Requests")),
      drawer: const MenuDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(child: Text("No requests found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    var request = requests[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(request["request_type"]),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status: ${request["status"]}"),
                            Text(
                              "Urgency: ${request["urgency"]}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: request["urgency"] == "High"
                                    ? Colors.red
                                    : request["urgency"] == "Medium"
                                        ? Colors.orange
                                        : Colors.green,
                              ),
                            ),
                            if (request["is_recurring"] == true)
                              Text("Repeats: ${request["recurring_type"]}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue)),
                          ],
                        ),
                        trailing: const Icon(Icons.info, color: Colors.blue),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRequestDialog(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddRequestDialog(BuildContext context) {
    TextEditingController descriptionController = TextEditingController();
    String selectedRequestType = "Time Off";
    String selectedUrgency = "Medium";
    bool isRecurring = false;
    String recurringType = "None";

    // Meeting fields
    DateTime? selectedDate;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;
    bool isTimeOpen = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Submit a Request",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  /// 🔹 Request Type Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedRequestType,
                    items: [
                      "Time Off",
                      "Expense",
                      "Meeting",
                      "Shift Change",
                      "Sick Time",
                      "Vacations"
                    ].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRequestType = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Request Type",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 🔹 Urgency Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedUrgency,
                    items: ["Low", "Medium", "High"].map((level) {
                      return DropdownMenuItem(value: level, child: Text(level));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedUrgency = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Urgency Level",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 🔹 Description Field
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Reason",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  /// 🔹 Show Meeting Options Only if "Meeting" is Selected
                  if (selectedRequestType == "Meeting") ...[
                    const SizedBox(height: 10),

                    /// 🔹 Open Meeting Time Option
                    CheckboxListTile(
                      title: const Text("Leave meeting time open"),
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
                    ),

                    /// 🔹 Meeting Date Picker (if not open-ended)
                    if (!isTimeOpen)
                      ListTile(
                        title: Text(selectedDate == null
                            ? "Select Meeting Date"
                            : "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}"),
                        leading: const Icon(Icons.calendar_today),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),

                    /// 🔹 Meeting Start Time Picker
                    if (!isTimeOpen)
                      ListTile(
                        title: Text(selectedStartTime == null
                            ? "Select Start Time"
                            : "Start Time: ${selectedStartTime!.format(context)}"),
                        leading: const Icon(Icons.access_time),
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              selectedStartTime = pickedTime;
                            });
                          }
                        },
                      ),

                    /// 🔹 Meeting End Time Picker
                    if (!isTimeOpen)
                      ListTile(
                        title: Text(selectedEndTime == null
                            ? "Select End Time"
                            : "End Time: ${selectedEndTime!.format(context)}"),
                        leading: const Icon(Icons.access_time),
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              selectedEndTime = pickedTime;
                            });
                          }
                        },
                      ),
                  ],

                  const SizedBox(height: 10),

                  // Recurring Request Toggle
                  SwitchListTile(
                    title: const Text("Make this request recurring"),
                    value: isRecurring,
                    onChanged: (bool value) {
                      setState(() {
                        isRecurring = value;
                        if (isRecurring) {
                          recurringType =
                              "Daily"; // ✅ Set a valid default value when toggled ON
                        } else {
                          recurringType = "None"; // ✅ Reset when toggled OFF
                        }
                      });
                    },
                  ),

// Recurring Type Dropdown (only shows if recurring is enabled)
                  if (isRecurring)
                    DropdownButtonFormField<String>(
                      value: recurringType, // ✅ Ensured this is a valid value
                      items: ["Daily", "Weekly", "Monthly"].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          recurringType = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Recurring Type",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                  /// 🔹 Submit Button
                  ElevatedButton(
                    onPressed: () async {
                      await PocketBaseService.submitRequest(
                        requestType: selectedRequestType,
                        description: descriptionController.text.trim(),
                        urgency: selectedUrgency,
                        isRecurring: isRecurring,
                        recurringType: isRecurring ? recurringType : null,
                        meetingDate: isTimeOpen ? null : selectedDate,
                        meetingStart: isTimeOpen ? null : selectedStartTime,
                        meetingEnd: isTimeOpen ? null : selectedEndTime,
                      );
                      loadRequests();
                      Navigator.pop(context);
                    },
                    child: const Text("Submit Request"),
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
