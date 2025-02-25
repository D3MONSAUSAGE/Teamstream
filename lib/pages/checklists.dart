import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/pages/execute_checklist.dart';
import 'package:teamstream/pages/revise_checklist.dart';

class ChecklistsPage extends StatefulWidget {
  const ChecklistsPage({super.key});

  @override
  ChecklistsPageState createState() => ChecklistsPageState();
}

class ChecklistsPageState extends State<ChecklistsPage> {
  List<Map<String, dynamic>> allChecklists = [];
  List<Map<String, dynamic>> availableChecklists = [];
  List<Map<String, dynamic>> completedChecklists = [];
  bool isLoading = true;

  // Date range filters
  DateTime? searchStartDate;
  DateTime? searchEndDate;

  @override
  void initState() {
    super.initState();
    loadChecklists();
  }

  void loadChecklists() async {
    List<Map<String, dynamic>> fetchedChecklists =
        await ChecklistsService.fetchChecklists();

    setState(() {
      allChecklists = fetchedChecklists;
      _applyDateFilter();
      isLoading = false;
    });
  }

  void _applyDateFilter() {
    List<Map<String, dynamic>> filtered = allChecklists;

    if (searchStartDate != null) {
      filtered = filtered.where((checklist) {
        if (checklist['start_time'] == null || checklist['start_time'] == "")
          return false;
        DateTime checklistDate = DateTime.parse(checklist['start_time']);
        // Include dates that are on or after the selected start date
        return checklistDate.isAtSameMomentAs(searchStartDate!) ||
            checklistDate.isAfter(searchStartDate!);
      }).toList();
    }

    if (searchEndDate != null) {
      filtered = filtered.where((checklist) {
        if (checklist['start_time'] == null || checklist['start_time'] == "")
          return false;
        DateTime checklistDate = DateTime.parse(checklist['start_time']);
        // Include dates that are on or before the selected end date
        return checklistDate.isAtSameMomentAs(searchEndDate!) ||
            checklistDate.isBefore(searchEndDate!);
      }).toList();
    }

    availableChecklists = filtered
        .where((checklist) => !(checklist['completed'] ?? false))
        .toList();
    completedChecklists =
        filtered.where((checklist) => checklist['completed'] ?? false).toList();
  }

  void _showAddChecklistDialog() {
    final _formKey = GlobalKey<FormState>();
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    List<String> shifts = ["Morning", "Afternoon", "Evening"];
    List<String> areas = ["Kitchen", "Customer Service"];
    String selectedShift = shifts.first;
    String selectedArea = areas.first;
    List<String> tasks = [];
    TextEditingController taskController = TextEditingController();
    DateTime? startTime;
    DateTime? endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Create New Checklist"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Field
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Checklist Title",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a title";
                        }
                        return null;
                      },
                    ),
                  ),
                  // Description Field
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                  ),
                  // Shift Dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownButtonFormField<String>(
                      value: selectedShift,
                      decoration: const InputDecoration(
                        labelText: "Select Shift",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: shifts
                          .map((shift) => DropdownMenuItem(
                                value: shift,
                                child: Text(shift),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedShift = value!;
                        });
                      },
                    ),
                  ),
                  // Area Dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownButtonFormField<String>(
                      value: selectedArea,
                      decoration: const InputDecoration(
                        labelText: "Select Area",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: areas
                          .map((area) => DropdownMenuItem(
                                value: area,
                                child: Text(area),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedArea = value!;
                        });
                      },
                    ),
                  ),
                  // Start Time Picker
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        startTime == null
                            ? "Select Start Time"
                            : DateFormat.jm().format(startTime!),
                      ),
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          DateTime now = DateTime.now();
                          setState(() {
                            startTime = DateTime(now.year, now.month, now.day,
                                picked.hour, picked.minute);
                          });
                        }
                      },
                    ),
                  ),
                  // End Time Picker
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        endTime == null
                            ? "Select End Time"
                            : DateFormat.jm().format(endTime!),
                      ),
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          DateTime now = DateTime.now();
                          setState(() {
                            endTime = DateTime(now.year, now.month, now.day,
                                picked.hour, picked.minute);
                          });
                        }
                      },
                    ),
                  ),
                  // Task Input Field
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: taskController,
                      decoration: InputDecoration(
                        labelText: "Enter Task",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (taskController.text.isNotEmpty) {
                              setState(() {
                                tasks.add(taskController.text);
                              });
                              taskController.clear();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  // Display Added Tasks
                  if (tasks.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: tasks
                          .map(
                            (task) => Chip(
                              label: Text(task),
                              onDeleted: () {
                                setState(() {
                                  tasks.remove(task);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() &&
                    startTime != null &&
                    endTime != null &&
                    tasks.isNotEmpty) {
                  try {
                    await ChecklistsService.createChecklist(
                      titleController.text,
                      descriptionController.text,
                      selectedShift,
                      startTime!.toIso8601String(),
                      endTime!.toIso8601String(),
                      selectedArea,
                      tasks,
                    );
                    loadChecklists();
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error creating checklist: $e")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please fill all required fields!")),
                  );
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        isExpanded: true,
        onChanged: (value) => onChanged(value!),
        items: options
            .map((option) =>
                DropdownMenuItem(value: option, child: Text(option)))
            .toList(),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    DateTime? selectedTime,
    Function(DateTime) onTimePicked,
  ) {
    return ListTile(
      title: Text(
          selectedTime == null ? label : DateFormat.jm().format(selectedTime)),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          DateTime now = DateTime.now();
          DateTime finalTime = DateTime(
              now.year, now.month, now.day, picked.hour, picked.minute);
          onTimePicked(finalTime);
        }
      },
    );
  }

  Widget _buildTaskInput(List<String> tasks, TextEditingController controller,
      Function(Function()) setState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: "Enter Task",
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      tasks.add(controller.text);
                    });
                    controller.clear();
                  }
                },
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: tasks
              .map((task) => Chip(
                    label: Text(task),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => setState(() {
                      tasks.remove(task);
                    }),
                  ))
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklists'),
        actions: [
          // Date range filter: Start Date Picker
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: "Select Start Date",
            onPressed: () async {
              DateTime? pickedStart = await showDatePicker(
                context: context,
                initialDate: searchStartDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pickedStart != null) {
                setState(() {
                  searchStartDate = pickedStart;
                  _applyDateFilter();
                });
              }
            },
          ),
          // Date range filter: End Date Picker
          IconButton(
            icon: const Icon(Icons.event),
            tooltip: "Select End Date",
            onPressed: () async {
              DateTime? pickedEnd = await showDatePicker(
                context: context,
                initialDate: searchEndDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pickedEnd != null) {
                setState(() {
                  searchEndDate = pickedEnd;
                  _applyDateFilter();
                });
              }
            },
          ),
          // Clear the date range filter if either is set
          if (searchStartDate != null || searchEndDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: "Clear Date Range",
              onPressed: () {
                setState(() {
                  searchStartDate = null;
                  searchEndDate = null;
                  _applyDateFilter();
                });
              },
            ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(10),
              children: [
                _buildChecklistSection(
                    "Available Checklists", availableChecklists),
                const SizedBox(height: 20),
                _buildChecklistSection(
                    "Completed Checklists", completedChecklists),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChecklistDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChecklistSection(
      String title, List<Map<String, dynamic>> checklists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...checklists.map((checklist) => _buildChecklistCard(checklist)),
      ],
    );
  }

  Widget _buildChecklistCard(Map<String, dynamic> checklist) {
    bool isCompleted = checklist['completed'] ?? false;
    bool isVerified = checklist['verified_by_manager'] ?? false;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(checklist['title'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(checklist['description'] ?? "No description available"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted && isVerified)
              const Icon(Icons.check_circle, color: Colors.green),
            ElevatedButton(
              onPressed: () {
                if (!isCompleted) {
                  // Check if current time is within the execution window.
                  if (!_isWithinExecutionWindow(checklist)) {
                    String start = checklist['start_time'];
                    String end = checklist['end_time'];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "This checklist can only be executed between $start and $end"),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExecuteChecklistPage(
                        checklistId: checklist['id'],
                      ),
                    ),
                  );
                } else {
                  if (!isVerified) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviseChecklistPage(
                          checklistId: checklist['id'],
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(isCompleted
                  ? (isVerified ? "Verified" : "Revise")
                  : "Execute"),
            ),
          ],
        ),
      ),
    );
  }

  bool _isWithinExecutionWindow(Map<String, dynamic> checklist) {
    try {
      DateTime start = DateTime.parse(checklist['start_time']);
      DateTime end = DateTime.parse(checklist['end_time']);
      DateTime now = DateTime.now();
      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      return false;
    }
  }
}
