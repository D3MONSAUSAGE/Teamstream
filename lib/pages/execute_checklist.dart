import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';
import 'package:teamstream/services/pocketbase/tasks_service.dart';

class ExecuteChecklistPage extends StatefulWidget {
  final String checklistId;
  const ExecuteChecklistPage({Key? key, required this.checklistId})
      : super(key: key);

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

  /// 🔹 Fetch checklist and associated tasks
  void loadChecklist() async {
    try {
      print("🔹 Fetching Checklist ID: ${widget.checklistId}");

      Map<String, dynamic> fetchedChecklist =
          await ChecklistsService.fetchChecklistById(widget.checklistId);
      List<Map<String, dynamic>> fetchedTasks =
          await TasksService.fetchTasksByChecklistId(widget.checklistId);

      print("✅ Loaded Checklist: $fetchedChecklist");
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

  /// 🔹 Toggle task completion
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

  /// 🔹 Check if all tasks are complete and mark checklist accordingly
  void checkChecklistCompletion() async {
    bool allCompleted =
        tasks.isNotEmpty && tasks.every((task) => task["is_completed"] == true);
    if (allCompleted) {
      await ChecklistsService.markChecklistCompleted(widget.checklistId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Checklist marked as completed!")),
        );
      }
    }
  }

  /// 🔹 Show note dialog for a task
  void _showNoteDialog(Map<String, dynamic> task) {
    TextEditingController noteController =
        TextEditingController(text: task["notes"] ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add/Edit Note"),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: "Note"),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String newNote = noteController.text;
              await TasksService.updateTaskNote(task["id"], newNote);
              setState(() {
                task["notes"] = newNote;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Pick an image (mobile: image_picker, web: file_picker) and update the task
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
