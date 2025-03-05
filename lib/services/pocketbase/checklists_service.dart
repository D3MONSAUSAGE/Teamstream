import 'package:teamstream/services/pocketbase/base_service.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/role_service.dart';

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
        List<String> repeatDays = [];
        if (checklist["repeat_days"] is String) {
          repeatDays = (checklist["repeat_days"] as String)
              .replaceAll("[", "")
              .replaceAll("]", "")
              .split(", ")
              .map((day) => day.trim())
              .toList();
        } else if (checklist["repeat_days"] is List) {
          repeatDays =
              (checklist["repeat_days"] as List<dynamic>).cast<String>();
        }

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
          "repeat_daily": checklist["repeat_daily"] ?? false,
          "repeat_days": repeatDays,
          "created_by": checklist["created_by"] ?? "",
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
        List<String> repeatDays = [];
        if (checklist["repeat_days"] is String) {
          repeatDays = (checklist["repeat_days"] as String)
              .replaceAll("[", "")
              .replaceAll("]", "")
              .split(", ")
              .map((day) => day.trim())
              .toList();
        } else if (checklist["repeat_days"] is List) {
          repeatDays =
              (checklist["repeat_days"] as List<dynamic>).cast<String>();
        }

        return {...checklist, "repeat_days": repeatDays};
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
      List<Map<String, dynamic>> tasks = await BaseService.fetchByField(
          tasksCollection, "checklist_id", checklistId);

      print("✅ Tasks for Checklist ($checklistId): $tasks");
      return tasks;
    } catch (e) {
      print("❌ Error fetching tasks for checklist $checklistId: $e");
      return [];
    }
  }

  /// 🔹 Create a new checklist with role validation
  static Future<String?> createChecklist(
    String title,
    String description,
    String shift,
    String startTime,
    String endTime,
    String area,
    List<String> tasks, {
    bool repeatDaily = false,
    List<String> repeatDays = const [],
  }) async {
    try {
      String? userId = AuthService.getLoggedInUserId();
      if (userId == null || !RoleService.canCreateChecklists()) {
        throw Exception(
            "❌ Access Denied: Only Shift Leaders and above can create checklists.");
      }

      // 🔹 Check if a checklist for the same time already exists
      bool checklistExists =
          await checkIfChecklistExists(DateTime.parse(startTime));
      if (checklistExists) {
        throw Exception("⚠️ Checklist for this time already exists.");
      }

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
        "repeat_daily": repeatDaily,
        "repeat_days": repeatDays,
        "created_by": userId, // Store creator ID
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
      return null;
    }
  }

  /// 🔹 Check if a checklist already exists for a given start time
  static Future<bool> checkIfChecklistExists(DateTime startTime) async {
    try {
      List<Map<String, dynamic>> checklists = await fetchChecklists();
      return checklists.any((checklist) {
        DateTime checklistStartTime = DateTime.parse(checklist["start_time"]);
        return checklistStartTime.isAtSameMomentAs(startTime);
      });
    } catch (e) {
      print("❌ Error checking if checklist exists: $e");
      return false;
    }
  }

  /// 🔹 Mark a checklist as completed
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
