import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/pages/execute_checklist.dart';

class ChecklistsPage extends StatefulWidget {
  const ChecklistsPage({super.key});

  @override
  ChecklistsPageState createState() => ChecklistsPageState();
}

class ChecklistsPageState extends State<ChecklistsPage> {
  List<Map<String, dynamic>> availableChecklists = [];
  List<Map<String, dynamic>> completedChecklists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadChecklists();
  }

  void loadChecklists() async {
    List<Map<String, dynamic>> fetchedChecklists =
        await ChecklistsService.fetchChecklists();

    setState(() {
      availableChecklists = fetchedChecklists
          .where((checklist) => !(checklist['completed'] ?? false))
          .toList();
      completedChecklists = fetchedChecklists
          .where((checklist) => checklist['completed'] ?? false)
          .toList();
      isLoading = false;
    });
  }

  void _showAddChecklistDialog() {
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
            child: Column(
              children: [
                _buildTextField("Checklist Title", titleController),
                _buildTextField("Description", descriptionController),
                _buildDropdown("Select Shift", shifts, selectedShift,
                    (value) => setState(() => selectedShift = value)),
                _buildDropdown("Select Area", areas, selectedArea,
                    (value) => setState(() => selectedArea = value)),
                _buildTimePicker("Select Start Time", startTime, (picked) {
                  setState(() => startTime = picked);
                }),
                _buildTimePicker("Select End Time", endTime, (picked) {
                  setState(() => endTime = picked);
                }),
                _buildTaskInput(tasks, taskController, setState),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    startTime != null &&
                    endTime != null &&
                    tasks.isNotEmpty) {
                  String checklistId = await ChecklistsService.createChecklist(
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
      appBar: AppBar(title: const Text('Checklists')),
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
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(checklist['title'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(checklist['description'] ?? "No description available"),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExecuteChecklistPage(
                  checklistId: checklist['id'],
                ),
              ),
            );
          },
          child: const Text("Execute"),
        ),
      ),
    );
  }
}
