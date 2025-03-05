import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';
import 'package:teamstream/services/pocketbase/tasks_service.dart';

class ReviseChecklistPage extends StatefulWidget {
  final String checklistId;

  const ReviseChecklistPage({super.key, required this.checklistId});

  @override
  _ReviseChecklistPageState createState() => _ReviseChecklistPageState();
}

class _ReviseChecklistPageState extends State<ReviseChecklistPage> {
  Map<String, dynamic>? checklist;
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadChecklist();
  }

  void loadChecklist() async {
    try {
      // Fetch checklist details
      Map<String, dynamic> fetchedChecklist =
          await ChecklistsService.fetchChecklistById(widget.checklistId);
      // Fetch tasks for the checklist
      List<Map<String, dynamic>> fetchedTasks =
          await TasksService.fetchTasksByChecklistId(widget.checklistId);
      setState(() {
        checklist = fetchedChecklist;
        tasks = fetchedTasks;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading checklist for revision: $e");
      setState(() => isLoading = false);
    }
  }

  void toggleTaskRevision(String taskId, bool? currentRevisionStatus) async {
    currentRevisionStatus ??= false;
    setState(() {
      tasks = tasks.map((task) {
        if (task["id"] == taskId) {
          return {...task, "is_revised": !currentRevisionStatus!};
        }
        return task;
      }).toList();
    });
    await TasksService.updateTaskRevision(taskId, !currentRevisionStatus);
  }

  void completeRevision() async {
    bool allRevised =
        tasks.isNotEmpty && tasks.every((task) => task["is_revised"] == true);
    if (allRevised) {
      await ChecklistsService.markChecklistVerified(widget.checklistId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("All tasks revised and checklist verified by manager!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Please revise all tasks before completing revision.")),
      );
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        Widget imageWidget;
        if (kIsWeb) {
          imageWidget = Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Text("Failed to load image"));
            },
          );
        } else {
          File file = File(imageUrl);
          if (!file.existsSync()) {
            imageWidget = const Center(child: Text("Image file not found"));
          } else {
            imageWidget = Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text("Failed to load image"));
              },
            );
          }
        }
        return Dialog(
          child: InteractiveViewer(child: imageWidget),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(checklist?["title"] ?? "Revise Checklist"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(child: Text("No tasks available for revision."))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: CheckboxListTile(
                        title: Text(task["name"] ?? "Unnamed Task"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task["notes"] != null &&
                                task["notes"].toString().trim().isNotEmpty)
                              Text("Note: ${task["notes"]}"),
                            if (task["file"] != null)
                              IconButton(
                                icon: const Icon(Icons.image),
                                tooltip: "View Uploaded Image",
                                onPressed: () {
                                  _showFullImage(task["file"]);
                                },
                              ),
                          ],
                        ),
                        value: task["is_revised"] ?? false,
                        onChanged: (bool? value) {
                          toggleTaskRevision(task["id"], task["is_revised"]);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: completeRevision,
        icon: const Icon(Icons.check),
        label: const Text("Complete Revision"),
      ),
    );
  }
}
