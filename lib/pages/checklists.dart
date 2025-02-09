import 'package:flutter/material.dart';
import 'package:teamstream/services/pocketbase_service.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class ChecklistsPage extends StatefulWidget {
  const ChecklistsPage({super.key});

  @override
  ChecklistsPageState createState() => ChecklistsPageState();
}

class ChecklistsPageState extends State<ChecklistsPage> {
  List<Map<String, dynamic>> availableChecklists = [];
  List<Map<String, dynamic>> executedChecklists = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadChecklists();
  }

  void loadChecklists() async {
    List<Map<String, dynamic>> fetchedChecklists =
        await PocketBaseService.fetchChecklists();
    setState(() {
      availableChecklists = fetchedChecklists
          .where((checklist) => !(checklist['completed'] ?? false))
          .toList();
      executedChecklists = fetchedChecklists
          .where((checklist) => checklist['completed'] ?? false)
          .toList();
      isLoading = false;
    });
  }

  void selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void _showAddChecklistDialog() {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController taskController = TextEditingController();
    List<String> shifts = ["Morning", "Afternoon", "Evening"];
    List<String> areas = ["Kitchen", "Customer Service"];
    String selectedShift = shifts.first;
    String selectedArea = areas.first;
    List<String> tasks = [];
    DateTime? startTime;
    DateTime? endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Create New Checklist"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Form for checklist details
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Checklist Title",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedShift,
                    decoration: InputDecoration(
                      labelText: "Select Shift",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                    ),
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        selectedShift = value!;
                      });
                    },
                    items: shifts.map((shift) {
                      return DropdownMenuItem(value: shift, child: Text(shift));
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedArea,
                    decoration: InputDecoration(
                      labelText: "Select Area",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                    ),
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        selectedArea = value!;
                      });
                    },
                    items: areas.map((area) {
                      return DropdownMenuItem(value: area, child: Text(area));
                    }).toList(),
                  ),
                ),
                // Time Selection
                ListTile(
                  title: Text(startTime == null
                      ? "Select Start Time"
                      : DateFormat.jm().format(startTime!)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        startTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            picked.hour,
                            picked.minute);
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text(endTime == null
                      ? "Select End Time"
                      : DateFormat.jm().format(endTime!)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        endTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            picked.hour,
                            picked.minute);
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                // Task Input
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: taskController,
                    decoration: InputDecoration(
                      labelText: "Enter Task",
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                    ),
                  ),
                ),
                // Task List
                Wrap(
                  spacing: 8,
                  children: tasks
                      .map((task) => Chip(
                            label: Text(task),
                            deleteIcon: const Icon(Icons.close),
                            onDeleted: () {
                              setState(() {
                                tasks.remove(task);
                              });
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    startTime != null &&
                    endTime != null &&
                    tasks.isNotEmpty) {
                  await PocketBaseService.createChecklist(
                    titleController.text,
                    descriptionController.text,
                    selectedShift,
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(startTime!),
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(endTime!),
                    tasks,
                    selectedArea,
                  );
                  loadChecklists();
                  Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklists'),
      ),
      drawer: const MenuDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: const Text('Available Checklists'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddChecklistDialog,
                  ),
                ),
                ...availableChecklists.map((checklist) => ListTile(
                      title: Text(checklist['title']),
                      subtitle: Text(checklist['description']),
                    )),
                const Divider(),
                ListTile(
                  title: const Text('Executed Checklists'),
                ),
                ...executedChecklists.map((checklist) => ListTile(
                      title: Text(checklist['title']),
                      subtitle: Text(checklist['description']),
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChecklistDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
