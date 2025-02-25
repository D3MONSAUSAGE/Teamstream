import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';
import 'package:http/http.dart' as http;

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
          .where((task) =>
              task.containsKey("checklist_id") &&
              task["checklist_id"] == checklistId)
          .toList();

      print("✅ Filtered Tasks for Checklist ($checklistId): $filteredTasks");
      print(
          "🔍 Checklist ID: $checklistId | Tasks Count: ${filteredTasks.length}");

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
        "checklist_id": checklistId,
        "name": title,
        "is_completed": false,
        "notes": "",
        "is_revised": false,
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

  /// 🔹 Update the note for a given task
  static Future<void> updateTaskNote(String taskId, String note) async {
    try {
      await BaseService.update(collectionName, taskId, {"notes": note});
      print("✅ Updated note for task $taskId: $note");
    } catch (e) {
      print("❌ Error updating note for task $taskId: $e");
    }
  }

  /// 🔹 Update the revision status for a given task
  static Future<void> updateTaskRevision(String taskId, bool isRevised) async {
    try {
      await BaseService.update(
          collectionName, taskId, {"is_revised": isRevised});
      print("✅ Task $taskId marked as revised: $isRevised");
    } catch (e) {
      print("❌ Error updating revision for task $taskId: $e");
    }
  }

  /// 🔹 Update the image for a given task (Mobile)
  static Future<void> updateTaskImage(String taskId, File imageFile) async {
    try {
      await BaseService.update(collectionName, taskId, {}, files: [imageFile]);
      print("✅ Updated image for task $taskId");
    } catch (e) {
      print("❌ Error updating image for task $taskId: $e");
    }
  }

  /// 🔹 Update the image for a given task (Web) and return the file URL
  static Future<String?> updateTaskImageWeb(
      String taskId, Uint8List fileBytes, String fileName) async {
    try {
      final multipartFile =
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName);
      await BaseService.update(collectionName, taskId, {},
          files: [multipartFile]);

      // Construct the URL based on your PocketBase file URL pattern.
      String fileUrl =
          "${BaseService.baseUrl}/api/files/$collectionName/$taskId/$fileName";

      print("✅ Updated image for task $taskId (Web): $fileUrl");
      return fileUrl;
    } catch (e) {
      print("❌ Error updating image for task $taskId on web: $e");
      return null;
    }
  }
}
