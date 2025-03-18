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
      rethrow; // ✅ Rethrow to allow callers to handle errors
    }
  }

  /// 🔹 Update task completion status (specific method)
  static Future<void> updateTaskCompletion(
      String taskId, bool isComplete) async {
    try {
      await BaseService.update(
          collectionName, taskId, {"is_complete": isComplete});
      print("✅ Task $taskId marked as completed: $isComplete");
    } catch (e) {
      print("❌ Error updating task completion $taskId: $e");
      rethrow;
    }
  }

  /// 🔹 Generic method to update any task fields
  static Future<void> updateTask(
      String taskId, Map<String, dynamic> data) async {
    try {
      await BaseService.update(collectionName, taskId, data);
      print("✅ Task $taskId updated with data: $data");
    } catch (e) {
      print("❌ Error updating task $taskId: $e");
      rethrow;
    }
  }

  /// 🔹 Create a new task for a checklist and return its ID
  static Future<String?> createTask(String checklistId, String title) async {
    try {
      Map<String, dynamic> taskData = {
        "checklist_id": checklistId,
        "name": title,
        "is_complete": false,
        "notes": "",
        "file": null,
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
      rethrow;
    }
  }

  /// 🔹 Update the note for a given task
  static Future<void> updateTaskNote(String taskId, String note) async {
    try {
      await BaseService.update(collectionName, taskId, {"notes": note});
      print("✅ Updated note for task $taskId: $note");
    } catch (e) {
      print("❌ Error updating note for task $taskId: $e");
      rethrow;
    }
  }

  /// 🔹 Update the image for a given task (Mobile)
  static Future<void> updateTaskImage(String taskId, File imageFile) async {
    try {
      await BaseService.update(collectionName, taskId, {}, files: [imageFile]);
      print("✅ Updated image for task $taskId");
    } catch (e) {
      print("❌ Error updating image for task $taskId: $e");
      rethrow;
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

      String fileUrl =
          "${BaseService.baseUrl}/api/files/$collectionName/$taskId/$fileName";
      print("✅ Updated image for task $taskId (Web): $fileUrl");
      return fileUrl;
    } catch (e) {
      print("❌ Error updating image for task $taskId on web: $e");
      rethrow;
    }
  }
}
