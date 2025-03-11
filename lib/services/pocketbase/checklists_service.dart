import 'package:teamstream/services/pocketbase/base_service.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/role_service.dart';

class ChecklistsService {
  static const String checklistCollection = "checklists";
  static const String tasksCollection = "tasks";

  /// 🔹 Fetch all checklists
  static Future<List<Map<String, dynamic>>> fetchChecklists() async {
    try {
      List<Map<String, dynamic>> fetchedData =
          await BaseService.fetchAll(checklistCollection);
      print("✅ Fetched ${fetchedData.length} checklists");
      return fetchedData;
    } catch (e) {
      print("❌ Error fetching checklists: $e");
      return [];
    }
  }

  /// 🔹 Fetch a checklist by ID
  static Future<Map<String, dynamic>?> fetchChecklistById(
      String checklistId) async {
    try {
      var checklist =
          await BaseService.fetchOne(checklistCollection, checklistId);
      if (checklist != null && checklist.isNotEmpty) {
        print("✅ Fetched checklist with ID: $checklistId");
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
          "repeat_days": checklist["repeat_days"] ?? [],
          "created_by": checklist["created_by"] ?? "",
        };
      } else {
        print("⚠️ Warning: Checklist with ID $checklistId not found.");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching checklist $checklistId: $e");
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

  /// 🔹 Create a new checklist
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
      bool hasPermission = RoleService.canCreateChecklists();

      if (userId == null || !hasPermission) {
        throw Exception(
            "❌ Access Denied: Only authorized users can create checklists.");
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
        "created_by": userId,
      };

      String? checklistId =
          await BaseService.create(checklistCollection, checklistBody);

      if (checklistId == null) {
        throw Exception("❌ Failed to create checklist.");
      }

      for (String taskName in tasks) {
        Map<String, dynamic> taskBody = {
          "checklist_id": checklistId,
          "name": taskName,
          "is_completed": false,
          "notes": "",
          "is_revised": false,
        };
        await BaseService.create(tasksCollection, taskBody);
      }

      return checklistId;
    } catch (e) {
      print("❌ Error creating checklist: $e");
      return null;
    }
  }

  /// 🔹 Mark a checklist as completed
  static Future<void> markChecklistCompleted(String checklistId) async {
    try {
      await BaseService.update(checklistCollection, checklistId, {
        "completed": true,
        "executed_at": DateTime.now().toIso8601String(),
      });
      print("✅ Checklist $checklistId marked as completed");
    } catch (e) {
      print("❌ Error marking checklist as completed: $e");
    }
  }

  /// 🔹 Mark a checklist as verified by manager
  static Future<void> markChecklistVerified(String checklistId) async {
    try {
      await BaseService.update(checklistCollection, checklistId, {
        "verified_by_manager": true,
      });
      print("✅ Checklist $checklistId marked as verified");
    } catch (e) {
      print("❌ Error verifying checklist: $e");
    }
  }
}
