import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    loadChecklist();
  }

  /// 🔹 Fetch checklist and associated tasks
  void loadChecklist() async {
    try {
      print("📥 Fetching Checklist ID: ${widget.checklistId}");

      Map<String, dynamic> fetchedChecklist =
          await ChecklistsService.fetchChecklistById(widget.checklistId);

      List<Map<String, dynamic>> fetchedTasks =
          await TasksService.fetchTasksByChecklistId(widget.checklistId);

      setState(() {
        checklist = fetchedChecklist;
        tasks = fetchedTasks;
        isLoading = false;
      });

      print("✅ Loaded Checklist: $checklist");
      print("✅ Loaded Tasks (${tasks.length}): $tasks");

      if (tasks.isEmpty) {
        print("⚠️ No tasks found for checklist ID: ${widget.checklistId}");
      }
    } catch (e) {
      print("❌ Error loading checklist: $e");
      setState(() => isLoading = false);
    }
  }

  /// 🔹 Toggle task completion
  void toggleTaskCompletion(String taskId, bool? currentStatus) async {
    if (currentStatus == null) {
      print("⚠️ Task completion status is null. Defaulting to false.");
      currentStatus = false;
    }

    print(
        "🔄 Toggling Task Completion: Task ID: $taskId | Current: $currentStatus");

    setState(() {
      tasks = tasks.map((task) {
        if (task["id"] == taskId) {
          return {
            ...task,
            "is_completed": !currentStatus!,
          };
        }
        return task;
      }).toList();
    });

    await TasksService.updateTaskCompletion(taskId, !currentStatus);
    checkChecklistCompletion();
  }

  /// 🔹 Mark checklist as completed if all tasks are done
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(checklist?["title"] ?? "Executing Checklist")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(
                  child: Text("⚠️ No tasks found for this checklist."),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];

                    print(
                        "🔹 Displaying Task: ${task['id']} | ${task['name']} | Completed: ${task['is_completed']}");

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: CheckboxListTile(
                        title: Text(task["name"] ?? "Unnamed Task"),
                        value: task["is_completed"] ??
                            false, // ✅ Handle null values
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
