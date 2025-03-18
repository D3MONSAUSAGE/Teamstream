import 'package:teamstream/services/pocketbase/base_service.dart';
import 'package:teamstream/services/pocketbase/role_service.dart';

class ChecklistsService {
  static const String checklistCollection = "checklists";
  static const String tasksCollection = "tasks";

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

  static Future<String> createChecklist(
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
      bool hasPermission = RoleService.canCreateChecklists();
      if (!hasPermission)
        throw Exception("❌ Access Denied: User lacks permission.");
      if (title.isEmpty) throw Exception("❌ Title is required.");
      if (shift.isEmpty) throw Exception("❌ Shift is required.");
      if (startTime.isEmpty) throw Exception("❌ Start time is required.");
      if (area.isEmpty) throw Exception("❌ Area is required.");

      const validShifts = [
        "Morning",
        "Afternoon",
        "Night",
        "Mid Shift",
        "Split Shift"
      ];
      const validAreas = ["Kitchen", "Customer Service"];
      if (!validShifts.contains(shift)) {
        throw Exception(
            "❌ Invalid shift value: $shift. Must be one of $validShifts");
      }
      if (!validAreas.contains(area)) {
        throw Exception(
            "❌ Invalid area value: $area. Must be one of $validAreas");
      }

      Map<String, dynamic> checklistBody = {
        "title": title.toString(),
        "description": description.toString(),
        "shift": shift,
        "start_time": startTime,
        "end_time": endTime.isEmpty ? "" : endTime,
        "area": area,
        "completed": false,
        "verified_by_manager": false,
        "executed_at": null,
        "repeat_daily": repeatDaily,
        "repeat_days": repeatDays,
      };

      print("📩 Creating checklist with body: $checklistBody");
      String? checklistId =
          await BaseService.create(checklistCollection, checklistBody);

      if (checklistId == null || checklistId.isEmpty) {
        throw Exception("❌ Failed to create checklist: No valid ID returned.");
      }
      print("✅ Checklist created with ID: $checklistId");

      for (String taskName in tasks) {
        Map<String, dynamic> taskBody = {
          "checklist_id": checklistId,
          "name": taskName,
          "is_complete": false,
          "notes": "",
          "file": null,
        };
        print("📩 Creating task: $taskBody");
        String? taskId = await BaseService.create(tasksCollection, taskBody);
        if (taskId == null) {
          print(
              "⚠️ Warning: Failed to create task '$taskName' for checklist $checklistId");
        } else {
          print("✅ Task created with ID: $taskId");
        }
      }

      return checklistId;
    } catch (e) {
      print("❌ Error creating checklist: $e");
      rethrow;
    }
  }

  static Future<void> markChecklistCompleted(String checklistId) async {
    try {
      await BaseService.update(checklistCollection, checklistId, {
        "completed": true,
        "executed_at": DateTime.now().toIso8601String(),
      });
      print("✅ Checklist $checklistId marked as completed");
    } catch (e) {
      print("❌ Error marking checklist as completed: $e");
      rethrow;
    }
  }

  static Future<void> markChecklistVerified(String checklistId) async {
    try {
      await BaseService.update(checklistCollection, checklistId, {
        "verified_by_manager": true,
      });
      print("✅ Checklist $checklistId marked as verified");
    } catch (e) {
      print("❌ Error marking checklist as verified: $e");
      rethrow;
    }
  }

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
          "verified_by_manager": checklist["verified_by_manager"] ?? false,
          "executed_at": checklist["executed_at"] ?? "",
          "start_time": checklist["start_time"] ?? "",
          "end_time": checklist["end_time"] ?? "",
          "repeat_daily": checklist["repeat_daily"] ?? false,
          "repeat_days": checklist["repeat_days"] ?? [],
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
}
