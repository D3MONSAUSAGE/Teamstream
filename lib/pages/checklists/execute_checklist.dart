import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';
import 'package:teamstream/services/pocketbase/tasks_service.dart';

class ExecuteChecklistPage extends StatefulWidget {
  final String checklistId;
  const ExecuteChecklistPage({super.key, required this.checklistId});

  @override
  ExecuteChecklistPageState createState() => ExecuteChecklistPageState();
}

class ExecuteChecklistPageState extends State<ExecuteChecklistPage> {
  Map<String, dynamic>? checklist;
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    setState(() => isLoading = true);
    try {
      Map<String, dynamic>? fetchedChecklist =
          await ChecklistsService.fetchChecklistById(widget.checklistId);
      if (fetchedChecklist == null) throw Exception("Checklist not found");

      List<Map<String, dynamic>> fetchedTasks =
          await TasksService.fetchTasksByChecklistId(widget.checklistId);

      if (mounted) {
        setState(() {
          checklist = fetchedChecklist;
          tasks = fetchedTasks;
          isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error loading checklist: $e', isError: true);
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage(Map<String, dynamic> task) async {
    try {
      if (kIsWeb) {
        FilePickerResult? result =
            await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null && result.files.isNotEmpty) {
          Uint8List fileBytes = result.files.first.bytes!;
          String fileName = result.files.first.name;
          String? fileUrl = await TasksService.updateTaskImageWeb(
              task["id"], fileBytes, fileName);
          if (fileUrl != null && mounted) {
            setState(() => task["file"] = fileUrl);
            _showSnackBar('Image uploaded successfully', isSuccess: true);
          }
        }
      } else {
        final XFile? pickedFile =
            await _picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          File imageFile = File(pickedFile.path);
          await TasksService.updateTaskImage(task["id"], imageFile);
          if (mounted) {
            setState(() => task["file"] = imageFile.path);
            _showSnackBar('Image uploaded successfully', isSuccess: true);
          }
        }
      }
    } catch (e) {
      _showSnackBar('Error uploading image: $e', isError: true);
    }
  }

  Future<void> _toggleTaskCompletion(String taskId, bool? currentStatus) async {
    bool newStatus = !(currentStatus ?? false);
    try {
      setState(() {
        tasks = tasks.map((task) {
          if (task["id"] == taskId) return {...task, "is_complete": newStatus};
          return task;
        }).toList();
      });

      await TasksService.updateTaskCompletion(taskId, newStatus);
      await _checkChecklistCompletion();
    } catch (e) {
      _showSnackBar('Error updating task: $e', isError: true);
      setState(() {
        tasks = tasks.map((task) {
          if (task["id"] == taskId) return {...task, "is_complete": !newStatus};
          return task;
        }).toList();
      });
    }
  }

  Future<void> _checkChecklistCompletion() async {
    bool allCompleted =
        tasks.isNotEmpty && tasks.every((task) => task["is_complete"] == true);
    if (allCompleted) {
      try {
        await ChecklistsService.markChecklistCompleted(widget.checklistId);
        if (checklist?["repeat_daily"] == true) {
          await _scheduleNextDailyChecklist();
        }
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar('Checklist marked as completed!', isSuccess: true);
        }
      } catch (e) {
        _showSnackBar('Error completing checklist: $e', isError: true);
      }
    }
  }

  Future<void> _scheduleNextDailyChecklist() async {
    try {
      DateTime startTime = DateTime.parse(checklist!["start_time"]);
      DateTime nextStartTime = startTime.add(const Duration(days: 1));

      bool checklistExists =
          await ChecklistsService.checkIfChecklistExists(nextStartTime);
      if (checklistExists) return;

      Map<String, dynamic> newChecklist = {
        ...checklist!,
        "start_time": nextStartTime.toIso8601String(),
        "end_time": DateTime(nextStartTime.year, nextStartTime.month,
                nextStartTime.day, startTime.hour, startTime.minute)
            .toIso8601String(),
        "completed": false,
        "verified_by_manager": false,
        "executed_at": "",
      };

      newChecklist.remove("id");

      await ChecklistsService.createChecklist(
        newChecklist["title"],
        newChecklist["description"],
        newChecklist["shift"],
        newChecklist["start_time"],
        newChecklist["end_time"],
        newChecklist["area"],
        tasks.map((task) => task["name"] as String).toList(),
        repeatDaily: true,
        repeatDays: List<String>.from(newChecklist["repeat_days"] ?? []),
      );
    } catch (e) {
      _showSnackBar('Error scheduling next daily checklist: $e', isError: true);
    }
  }

  void _showNoteDialog(Map<String, dynamic> task) {
    TextEditingController noteController =
        TextEditingController(text: task["notes"]);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          title: Text(
            'Add/Edit Note',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: 'Enter your note here',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await TasksService.updateTaskNote(
                      task["id"], noteController.text);
                  if (mounted) {
                    setState(() => task["notes"] = noteController.text);
                    _showSnackBar('Note saved successfully', isSuccess: true);
                  }
                  Navigator.pop(context);
                } catch (e) {
                  _showSnackBar('Error saving note: $e', isError: true);
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
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
    bool allTasksCompleted =
        tasks.isNotEmpty && tasks.every((task) => task["is_complete"] == true);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          checklist?["title"] ?? 'Executing Checklist',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _loadChecklist,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : tasks.isEmpty
              ? Center(
                  child: Text(
                    'No tasks found for this checklist',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 12),
                    _buildTasksList(),
                  ],
                ),
      floatingActionButton: allTasksCompleted
          ? FloatingActionButton.extended(
              onPressed: _checkChecklistCompletion,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                'Finish Checklist',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.blueAccent,
            )
          : null,
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checklist Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            if (checklist != null) ...[
              Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatTime(checklist!["start_time"])} - ${_formatTime(checklist!["end_time"])}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.work, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(
                    checklist!["shift"] ?? 'No Shift',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(
                    checklist!["area"] ?? 'Unknown Area',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                var task = tasks[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: CheckboxListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            task["name"] ?? 'Unnamed Task',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.note,
                              color: Colors.blueAccent, size: 20),
                          tooltip: 'Add/Edit Note',
                          onPressed: () => _showNoteDialog(task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.blueAccent, size: 20),
                          tooltip: 'Upload Picture',
                          onPressed: () => _pickImage(task),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task["notes"]?.toString().trim().isNotEmpty ??
                            false)
                          Text(
                            '📝 ${task["notes"]}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        if (task["file"] != null &&
                            task["file"].toString().isNotEmpty)
                          Text(
                            '📷 Image attached',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    value: task["is_complete"] ?? false,
                    onChanged: (bool? value) =>
                        _toggleTaskCompletion(task["id"], task["is_complete"]),
                    activeColor: Colors.blueAccent,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String time) {
    try {
      return DateFormat.jm().format(DateTime.parse(time));
    } catch (e) {
      return 'Invalid Time';
    }
  }
}
