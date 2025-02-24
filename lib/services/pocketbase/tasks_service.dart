import 'package:teamstream/services/pocketbase/base_service.dart';

class TasksService {
  static const String collectionName = "tasks";

  /// 🔹 Fetch tasks for a given checklist
  static Future<List<Map<String, dynamic>>> fetchTasksByChecklistId(
      String checklistId) async {
    try {
      List<Map<String, dynamic>> fetchedTasks =
          await BaseService.fetchAll(collectionName);

      print("📥 Fetched Tasks (Raw): $fetchedTasks");

      List<Map<String, dynamic>> filteredTasks = fetchedTasks
          .where((task) => task["checklist_id"] == checklistId)
          .toList();

      print("✅ Filtered Tasks for Checklist ($checklistId): $filteredTasks");

      return filteredTasks;
    } catch (e) {
      print("❌ Error fetching tasks for checklist $checklistId: $e");
      return [];
    }
  }

  /// 🔹 Update task completion status
  static Future<void> updateTaskCompletion(
      String taskId, bool isCompleted) async {
    try {
      await BaseService.update(
          collectionName, taskId, {"is_completed": isCompleted});
      print("✅ Task $taskId marked as completed: $isCompleted");
    } catch (e) {
      print("❌ Error updating task $taskId: $e");
    }
  }

  /// 🔹 Create a new task for a checklist and return its ID
  static Future<String?> createTask(String checklistId, String title) async {
    try {
      Map<String, dynamic> taskData = {
        "checklist_id": checklistId, // ✅ Ensure task is linked to checklist
        "name": title, // ✅ Store task name
        "is_completed": false, // ✅ Default completion status
        "note": "", // ✅ Default note is an empty string
        "created_at":
            DateTime.now().toIso8601String(), // ✅ Store creation timestamp
      };

      String? taskId = await BaseService.create(collectionName, taskData);

      if (taskId == null) {
        print("❌ Failed to create task for checklist: $checklistId");
      } else {
        print("✅ Task Created: ID $taskId, Title: $title");
      }

      return taskId;
    } catch (e) {
      print("❌ Error creating task: $e");
      return null;
    }
  }
}
