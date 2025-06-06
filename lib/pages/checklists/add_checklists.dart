import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/tasks_service.dart';

class AddChecklistDialog extends StatefulWidget {
  final VoidCallback onChecklistCreated;
  final Map<String, dynamic>? checklistToEdit;

  const AddChecklistDialog({
    super.key,
    required this.onChecklistCreated,
    this.checklistToEdit,
  });

  @override
  AddChecklistDialogState createState() => AddChecklistDialogState();
}

class AddChecklistDialogState extends State<AddChecklistDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController taskController = TextEditingController();
  final List<String> shifts = [
    "Morning",
    "Afternoon",
    "Night",
    "Mid Shift",
    "Split Shift",
  ];
  final List<String> areas = ["Kitchen", "Customer Service"];
  String selectedShift = "Morning";
  String selectedArea = "Kitchen";
  List<Map<String, dynamic>> tasks = [];
  DateTime? startTime;
  DateTime? endTime;
  bool repeatDaily = false;
  bool isSubmitting = false;

  final List<String> daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  final Map<String, bool> selectedDays = {
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
    "Thursday": false,
    "Friday": false,
    "Saturday": false,
    "Sunday": false,
  };

  String? currentUserRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    if (widget.checklistToEdit != null) {
      _populateFields(widget.checklistToEdit!);
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      String? userId = AuthService.getLoggedInUserId();
      if (userId != null) {
        currentUserRole = AuthService.getRole();
        print("🛠️ Current user role in AddChecklistDialog: $currentUserRole");
      } else {
        currentUserRole = "Unknown";
        print("❌ No user ID found in AddChecklistDialog");
      }
      setState(() {});
    } catch (e) {
      print("❌ Error fetching user role: $e");
      currentUserRole = "Error";
      setState(() {});
    }
  }

  Future<void> _populateFields(Map<String, dynamic> checklist) async {
    titleController.text = checklist['title'] ?? '';
    descriptionController.text = checklist['description'] ?? '';
    selectedShift = checklist['shift'] ?? shifts[0];
    selectedArea = checklist['area'] ?? areas[0];
    startTime = DateTime.parse(checklist['start_time']);
    endTime = DateTime.parse(checklist['end_time']);
    repeatDaily = checklist['repeat_daily'] ?? false;

    final repeatDays = List<String>.from(checklist['repeat_days'] ?? []);
    for (var day in daysOfWeek) {
      selectedDays[day] = repeatDays.contains(day);
    }

    // Fetch existing tasks
    try {
      final fetchedTasks =
          await TasksService.fetchTasksByChecklistId(checklist['id']);
      setState(() {
        tasks = fetchedTasks;
      });
    } catch (e) {
      print("❌ Error fetching tasks for checklist ${checklist['id']}: $e");
      _showSnackBar('Error loading tasks: $e', isError: true);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.checklistToEdit != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Form(
          key: _formKey,
          child: isSubmitting
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Checklist' : 'Create New Checklist',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Role: ${currentUserRole ?? "Loading..."}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: titleController,
                        label: 'Checklist Title',
                        icon: Icons.title,
                        validator: (value) =>
                            value!.isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: descriptionController,
                        label: 'Description',
                        icon: Icons.description,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        value: selectedShift,
                        items: shifts,
                        label: 'Shift',
                        icon: Icons.schedule,
                        onChanged: (value) =>
                            setState(() => selectedShift = value!),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Shift is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        value: selectedArea,
                        items: areas,
                        label: 'Area',
                        icon: Icons.location_on,
                        onChanged: (value) =>
                            setState(() => selectedArea = value!),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Area is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTimePicker(
                        'Start Time',
                        startTime,
                        (picked) => setState(() => startTime = picked),
                      ),
                      const SizedBox(height: 12),
                      _buildTimePicker(
                        'End Time',
                        endTime,
                        (picked) => setState(() => endTime = picked),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: Text(
                          'Repeat Daily',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        value: repeatDaily,
                        activeColor: Colors.blueAccent,
                        onChanged: (value) =>
                            setState(() => repeatDaily = value),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (repeatDaily) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Select Days:',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: daysOfWeek
                              .map((day) => FilterChip(
                                    label: Text(day,
                                        style:
                                            GoogleFonts.poppins(fontSize: 12)),
                                    selected: selectedDays[day]!,
                                    selectedColor:
                                        Colors.blueAccent.withOpacity(0.3),
                                    onSelected: (value) => setState(
                                        () => selectedDays[day] = value),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildTaskInput(),
                      if (tasks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: tasks
                              .map((task) => Chip(
                                    label: Text(task['name'],
                                        style:
                                            GoogleFonts.poppins(fontSize: 12)),
                                    backgroundColor:
                                        Colors.blueAccent.withOpacity(0.1),
                                    deleteIcon: const Icon(Icons.close,
                                        size: 16, color: Colors.grey),
                                    onDeleted: () =>
                                        setState(() => tasks.remove(task)),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isSubmitting ? null : _submitChecklist,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              isEditing ? 'Update' : 'Create',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: GoogleFonts.poppins(),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: GoogleFonts.poppins()),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildTimePicker(
      String label, DateTime? time, Function(DateTime) onPicked) {
    return GestureDetector(
      onTap: () async {
        TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime:
              time != null ? TimeOfDay.fromDateTime(time) : TimeOfDay.now(),
          builder: (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          final now = DateTime.now();
          onPicked(now.copyWith(hour: picked.hour, minute: picked.minute));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                time == null ? 'Select $label' : DateFormat.jm().format(time),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: time == null ? Colors.grey[700] : Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInput() {
    return TextFormField(
      controller: taskController,
      decoration: InputDecoration(
        labelText: 'Add Task',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: const Icon(Icons.task, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
          onPressed: () {
            if (taskController.text.trim().isNotEmpty) {
              setState(() {
                tasks.add({
                  'name': taskController.text.trim(),
                  'is_complete': false,
                  'notes': '',
                  'file': null,
                });
                taskController.clear();
              });
            }
          },
        ),
      ),
      style: GoogleFonts.poppins(),
      onFieldSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          setState(() {
            tasks.add({
              'name': value.trim(),
              'is_complete': false,
              'notes': '',
              'file': null,
            });
            taskController.clear();
          });
        }
      },
    );
  }

  Future<void> _submitChecklist() async {
    if (_formKey.currentState!.validate() &&
        startTime != null &&
        endTime != null &&
        tasks.isNotEmpty) {
      setState(() => isSubmitting = true);
      try {
        final selectedDayList = selectedDays.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

        if (widget.checklistToEdit != null) {
          // Update existing checklist
          await ChecklistsService.updateChecklist(
            widget.checklistToEdit!['id'],
            titleController.text.trim(),
            descriptionController.text.trim(),
            selectedShift,
            startTime!.toIso8601String(),
            endTime!.toIso8601String(),
            selectedArea,
            tasks,
            repeatDaily: repeatDaily,
            repeatDays: selectedDayList,
          );
          _showSnackBar('Checklist updated successfully', isSuccess: true);
        } else {
          // Create new checklist
          await ChecklistsService.createChecklist(
            titleController.text.trim(),
            descriptionController.text.trim(),
            selectedShift,
            startTime!.toIso8601String(),
            endTime!.toIso8601String(),
            selectedArea,
            tasks
                .map((task) => task['name'] as String)
                .toList(), // Extract names
            repeatDaily: repeatDaily,
            repeatDays: selectedDayList,
          );
          _showSnackBar('Checklist created successfully', isSuccess: true);
        }

        widget.onChecklistCreated();
        Navigator.pop(context);
      } catch (e) {
        _showSnackBar(
            'Error ${widget.checklistToEdit != null ? 'updating' : 'creating'} checklist: $e',
            isError: true);
      } finally {
        setState(() => isSubmitting = false);
      }
    } else {
      _showSnackBar(
        'Please complete all required fields and add at least one task',
        isError: true,
      );
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
}
