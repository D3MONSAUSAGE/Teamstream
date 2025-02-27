import 'package:teamstream/services/pocketbase/base_service.dart';

class ChecklistsService {
  static const String checklistCollection = "checklists";
  static const String tasksCollection = "tasks";

  /// 🔹 Fetch all checklists, optionally filtering by a specific date.
  static Future<List<Map<String, dynamic>>> fetchChecklists(
      {DateTime? searchDate}) async {
    try {
      List<Map<String, dynamic>> fetchedData =
          await BaseService.fetchAll(checklistCollection);

      List<Map<String, dynamic>> checklists = fetchedData.map((checklist) {
        return {
          "id": checklist["id"],
          "title": checklist["title"] ?? "Untitled",
          "description": checklist["description"] ?? "",
          "shift": checklist["shift"] ?? "",
          "area": checklist["area"] ?? "",
          "completed": checklist["completed"] ?? false,
          "executed_at": checklist["executed_at"] ?? "",
          "verified_by_manager": checklist["verified_by_manager"] ?? false,
          "start_time": checklist["start_time"] ?? "",
          "end_time": checklist["end_time"] ?? "",
        };
      }).toList();

      if (searchDate != null) {
        checklists = checklists.where((checklist) {
          if (checklist['start_time'] == null ||
              checklist['start_time'] == "") {
            return false;
          }
          DateTime checklistDate = DateTime.parse(checklist['start_time']);
          return checklistDate.year == searchDate.year &&
              checklistDate.month == searchDate.month &&
              checklistDate.day == searchDate.day;
        }).toList();
      }

      return checklists;
    } catch (e) {
      print("❌ Error fetching checklists: $e");
      return [];
    }
  }

  /// 🔹 Fetch a checklist by ID
  static Future<Map<String, dynamic>> fetchChecklistById(
      String checklistId) async {
    try {
      var checklist =
          await BaseService.fetchOne(checklistCollection, checklistId);
      if (checklist != null && checklist.isNotEmpty) {
        return checklist;
      } else {
        print("⚠️ Warning: Checklist with ID $checklistId not found.");
        return {};
      }
    } catch (e) {
      print("❌ Error fetching checklist $checklistId: $e");
      return {};
    }
  }

  /// 🔹 Fetch tasks for a given checklist
  static Future<List<Map<String, dynamic>>> fetchTasks(
      String checklistId) async {
    try {
      List<Map<String, dynamic>> tasks =
          await BaseService.fetchAll(tasksCollection);

      List<Map<String, dynamic>> filteredTasks =
          tasks.where((task) => task["checklist_id"] == checklistId).toList();

      print("✅ Tasks for Checklist ($checklistId): $filteredTasks");
      return filteredTasks;
    } catch (e) {
      print("❌ Error fetching tasks for checklist $checklistId: $e");
      return [];
    }
  }

  /// 🔹 Create a new checklist and return its ID
  static Future<String> createChecklist(
    String title,
    String description,
    String shift,
    String startTime,
    String endTime,
    String area,
    List<String> tasks,
  ) async {
    try {
      // Create checklist
      Map<String, dynamic> checklistBody = {
        "title": title,
        "description": description,
        "shift": shift,
        "start_time": startTime,
        "end_time": endTime,
        "area": area,
        "completed": false,
        "verified_by_manager": false,
        "executed_at": null,
      };

      String? checklistId =
          await BaseService.create(checklistCollection, checklistBody);

      if (checklistId == null) {
        throw Exception("❌ Failed to create checklist.");
      }

      print("✅ Checklist Created with ID: $checklistId");

      // Add tasks to the checklist
      for (String taskName in tasks) {
        await BaseService.create(tasksCollection, {
          "checklist_id": checklistId,
          "name": taskName,
          "is_completed": false,
          "notes": "",
          "is_revised": false,
        });
      }

      return checklistId;
    } catch (e) {
      print("❌ Error creating checklist: $e");
      rethrow;
    }
  }

  /// 🔹 Mark a checklist as completed if all tasks are done
  static Future<void> checkAndCompleteChecklist(String checklistId) async {
    try {
      List<Map<String, dynamic>> tasks = await fetchTasks(checklistId);

      if (tasks.isNotEmpty &&
          tasks.every((task) => task['is_completed'] == true)) {
        await BaseService.update(checklistCollection, checklistId, {
          "completed": true,
          "executed_at": DateTime.now().toIso8601String(),
        });
        print("✅ Checklist $checklistId marked as completed");
      }
    } catch (e) {
      print("❌ Error completing checklist $checklistId: $e");
    }
  }

  /// 🔹 Manually mark a checklist as completed
  static Future<void> markChecklistCompleted(String checklistId) async {
    try {
      await BaseService.update(checklistCollection, checklistId, {
        "completed": true,
        "executed_at": DateTime.now().toIso8601String(),
      });
      print("✅ Checklist $checklistId manually marked as completed");
    } catch (e) {
      print("❌ Error marking checklist $checklistId as completed: $e");
    }
  }

  /// 🔹 Mark a checklist as verified by manager
  static Future<void> markChecklistVerified(String checklistId) async {
    try {
      await BaseService.update(checklistCollection, checklistId, {
        "verified_by_manager": true,
      });
      print("✅ Checklist $checklistId marked as verified by manager");
    } catch (e) {
      print("❌ Error verifying checklist $checklistId: $e");
    }
  }
}
