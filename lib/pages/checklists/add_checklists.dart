import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';

class AddChecklistDialog extends StatefulWidget {
  final VoidCallback onChecklistCreated;

  const AddChecklistDialog({super.key, required this.onChecklistCreated});

  @override
  AddChecklistDialogState createState() => AddChecklistDialogState();
}

class AddChecklistDialogState extends State<AddChecklistDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final List<String> shifts = ["Morning", "Afternoon", "Evening"];
  final List<String> areas = ["Kitchen", "Customer Service"];
  String selectedShift = "Morning";
  String selectedArea = "Kitchen";
  final List<String> tasks = [];
  final TextEditingController taskController = TextEditingController();
  DateTime? startTime;
  DateTime? endTime;
  bool repeatDaily = false;

  // Days of the week
  final List<String> daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  // Selected days for repeating checklists
  final Map<String, bool> selectedDays = {
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
    "Thursday": false,
    "Friday": false,
    "Saturday": false,
    "Sunday": false,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
              // Repeat Daily Switch
              SwitchListTile(
                title: const Text("Repeat Daily"),
                value: repeatDaily,
                onChanged: (value) {
                  setState(() {
                    repeatDaily = value;
                  });
                },
              ),
              // Day Selector (only visible if repeatDaily is true)
              if (repeatDaily)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Select Days:",
                        style: TextStyle(fontSize: 16),
                      ),
                      Wrap(
                        spacing: 8,
                        children: daysOfWeek.map((day) {
                          return FilterChip(
                            label: Text(day),
                            selected: selectedDays[day]!,
                            onSelected: (value) {
                              setState(() {
                                selectedDays[day] = value;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
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
                // Get selected days
                List<String> selectedDayList = selectedDays.entries
                    .where((entry) => entry.value)
                    .map((entry) => entry.key)
                    .toList();

                // Format startTime and endTime as strings
                String formattedStartTime =
                    DateFormat("yyyy-MM-ddTHH:mm:ss").format(startTime!);
                String formattedEndTime =
                    DateFormat("yyyy-MM-ddTHH:mm:ss").format(endTime!);

                await ChecklistsService.createChecklist(
                  titleController.text,
                  descriptionController.text,
                  selectedShift,
                  formattedStartTime,
                  formattedEndTime,
                  selectedArea,
                  tasks,
                  repeatDaily: repeatDaily,
                  repeatDays: selectedDayList,
                );
                widget.onChecklistCreated();
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
    );
  }
}
