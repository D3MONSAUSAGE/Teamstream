import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
    loadChecklist();
  }

  void loadChecklist() async {
    try {
      print("🔹 Fetching Checklist ID: ${widget.checklistId}");

      Map<String, dynamic> fetchedChecklist =
          await ChecklistsService.fetchChecklistById(widget.checklistId)
              as Map<String, dynamic>;
      print("✅ Loaded Checklist: $fetchedChecklist");

      List<Map<String, dynamic>> fetchedTasks =
          await TasksService.fetchTasksByChecklistId(widget.checklistId);
      print("✅ Loaded Tasks (${fetchedTasks.length}): $fetchedTasks");

      if (mounted) {
        setState(() {
          checklist = fetchedChecklist;
          tasks = fetchedTasks;
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error loading checklist: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage(Map<String, dynamic> task) async {
    if (kIsWeb) {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty) {
        Uint8List fileBytes = result.files.first.bytes!;
        String fileName = result.files.first.name;
        String? fileUrl = await TasksService.updateTaskImageWeb(
            task["id"], fileBytes, fileName);
        if (fileUrl != null) {
          setState(() {
            task["file"] = fileUrl;
          });
        }
      }
    } else {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        await TasksService.updateTaskImage(task["id"], imageFile);
        setState(() {
          task["file"] = imageFile.path;
        });
      }
    }
  }

  void toggleTaskCompletion(String taskId, bool? currentStatus) async {
    bool nonNullStatus = currentStatus ?? false;

    setState(() {
      tasks = tasks.map((task) {
        if (task["id"] == taskId) {
          return {...task, "is_completed": !nonNullStatus};
        }
        return task;
      }).toList();
    });

    await TasksService.updateTaskCompletion(taskId, !nonNullStatus);
    checkChecklistCompletion();
  }

  void checkChecklistCompletion() async {
    bool allCompleted =
        tasks.isNotEmpty && tasks.every((task) => task["is_completed"] == true);
    if (allCompleted) {
      await ChecklistsService.markChecklistCompleted(widget.checklistId);

      if (checklist?["repeat_daily"] == true) {
        await _scheduleNextDailyChecklist();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Checklist marked as completed!")),
        );
      }
    }
  }

  Future<void> _scheduleNextDailyChecklist() async {
    try {
      DateTime startTime = DateTime.parse(checklist!["start_time"]);
      DateTime nextStartTime = startTime.add(const Duration(days: 1));

      bool checklistExists =
          await ChecklistsService.checkIfChecklistExists(nextStartTime);
      if (checklistExists) {
        print("⚠️ Checklist for $nextStartTime already exists.");
        return;
      }

      Map<String, dynamic> newChecklist = {
        ...checklist!,
        "start_time": nextStartTime.toIso8601String(),
        "end_time": DateTime(nextStartTime.year, nextStartTime.month,
                nextStartTime.day, startTime.hour, startTime.minute)
            .toIso8601String(),
        "completed": false,
        "verified_by_manager": false,
        "executed_at": null,
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
      );

      print("✅ Scheduled next daily checklist for $nextStartTime");
    } catch (e) {
      print("❌ Error scheduling next daily checklist: $e");
    }
  }

  void _showNoteDialog(Map<String, dynamic> task) {
    TextEditingController noteController =
        TextEditingController(text: task["notes"]);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add/Edit Note"),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: "Enter your note here"),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () {
                setState(() {
                  task["notes"] = noteController.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(checklist?["title"] ?? "Executing Checklist")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(
                  child: Text("⚠️ No tasks found for this checklist."))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: CheckboxListTile(
                        title: Row(
                          children: [
                            Expanded(
                                child: Text(task["name"] ?? "Unnamed Task")),
                            IconButton(
                              icon: const Icon(Icons.note),
                              tooltip: "Add/Edit Note",
                              onPressed: () {
                                _showNoteDialog(task);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.camera_alt),
                              tooltip: "Upload Picture",
                              onPressed: () {
                                _pickImage(task);
                              },
                            ),
                          ],
                        ),
                        subtitle: (task["notes"] != null &&
                                task["notes"].toString().trim().isNotEmpty)
                            ? Text("📝 Note: ${task["notes"]}")
                            : null,
                        value: task["is_completed"] ?? false,
                        onChanged: (bool? value) {
                          toggleTaskCompletion(
                              task["id"], task["is_completed"]);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: checkChecklistCompletion,
        icon: const Icon(Icons.check),
        label: const Text("Complete Checklist"),
      ),
    );
  }
}
