import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';

class PocketBaseService {
  static final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  /// 🔹 Authenticate and log in the user, returning the user ID
  static Future<String?> login(String email, String password) async {
    try {
      final authResponse =
          await pb.collection('users').authWithPassword(email, password);

      String userId = authResponse.record.id;
      AuthService.setLoggedInUser(userId);
      print("✅ Successfully logged in. User ID: $userId");
      return userId;
    } catch (e) {
      print("❌ Login failed: $e");
      return null;
    }
  }

  /// 🔹 Log out the user
  static void logout() {
    pb.authStore.clear();
    AuthService.clearLoggedInUser();
    print("✅ User logged out.");
  }

  /// 🔹 Get the Logged-in User ID
  /// 🔹 Get the Logged-in User ID (With Validation)
  static String? getLoggedInUserId() {
    String? userId = AuthService.getLoggedInUserId();
    if (userId == null || userId.isEmpty) {
      print("❌ No logged-in user found.");
      return null;
    }
    return userId;
  }

  /// 🔹 Submit Employee Request (Handles all request types)
  static Future<bool> submitRequest({
    required String requestType,
    required String description,
    required String urgency,
    bool isRecurring = false,
    String? recurringType,
    DateTime? meetingDate,
    TimeOfDay? meetingStart,
    TimeOfDay? meetingEnd,
    bool isTimeOpen = false,
    FilePickerResult? attachment,
  }) async {
    try {
      String? userId = getLoggedInUserId();
      if (userId == null) {
        throw Exception("❌ Cannot submit request: User ID is null.");
      }

      // ✅ Prepare request data
      Map<String, dynamic> requestData = {
        "request_type": requestType,
        "description": description,
        "urgency": urgency,
        "status": "Pending",
        "submitted_by": userId,
        "is_recurring": isRecurring,
        "recurring_type": isRecurring ? recurringType : null,
        "next_occurrence": isRecurring
            ? DateTime.now().add(Duration(
                days: recurringType == "Daily"
                    ? 1
                    : recurringType == "Weekly"
                        ? 7
                        : 30))
            : null,
        "is_time_open": isTimeOpen, // ✅ Store if the meeting time is open
      };

      // ✅ Only add meeting-related fields if it's a meeting request
      if (requestType == "Meeting" && !isTimeOpen) {
        requestData["meeting_date"] = meetingDate?.toIso8601String();
        requestData["meeting_start"] = meetingStart != null
            ? "${meetingStart.hour.toString().padLeft(2, '0')}:${meetingStart.minute.toString().padLeft(2, '0')}"
            : null;
        requestData["meeting_end"] = meetingEnd != null
            ? "${meetingEnd.hour.toString().padLeft(2, '0')}:${meetingEnd.minute.toString().padLeft(2, '0')}"
            : null;
      }

      // ✅ Submit the request
      RecordModel requestRecord =
          await pb.collection('requests').create(body: requestData);
      String requestId = requestRecord.id;

      // ✅ Handle attachments
      if (attachment != null) {
        Uint8List fileBytes = attachment.files.single.bytes!;
        String fileName = attachment.files.single.name;

        final multipartFile = http.MultipartFile.fromBytes(
          'attachment',
          fileBytes,
          filename: fileName,
        );

        await pb
            .collection('requests')
            .update(requestId, files: [multipartFile]);
      }

      print("✅ Request submitted successfully: $requestId");
      return true;
    } catch (e) {
      print("❌ Error submitting request: $e");
      return false;
    }
  }

  /// 🔹 Fetch Requests (User & Admin)
  static Future<List<Map<String, dynamic>>> fetchRequests(
      {bool isAdmin = false}) async {
    try {
      String? userId = getLoggedInUserId();
      if (userId == null) throw Exception("User ID is null");

      final filter = isAdmin ? "" : "submitted_by = '$userId'";
      final records =
          await pb.collection('requests').getFullList(filter: filter);
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("❌ Error fetching requests: $e");
      return [];
    }
  }

  /// 🔹 Approve or Reject a Request
  static Future<void> updateRequestStatus(
      String requestId, String status) async {
    try {
      await pb
          .collection('requests')
          .update(requestId, body: {"status": status});
      print("✅ Request $requestId updated to $status");
    } catch (e) {
      print("❌ Error updating request status: $e");
    }
  }

  /// 🔹 Fetch Assigned Schedules
  static Future<List<Map<String, dynamic>>> fetchAssignedSchedules() async {
    try {
      final records = await pb.collection('schedules').getFullList();
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("❌ Error fetching assigned schedules: $e");
      return [];
    }
  }

  /// 🔹 Create a Checklist
  static Future<void> createChecklist(
    String title,
    String description,
    String shift,
    String startTime,
    String endTime,
    List<String> tasks,
    String area,
  ) async {
    try {
      await pb.collection('checklists').create(body: {
        "title": title,
        "description": description,
        "shift": shift,
        "start_time": startTime,
        "end_time": endTime,
        "tasks": tasks,
        "area": area,
        "completed": false,
        "verified_by_manager": false,
        "executed_at": null,
      });
      print("✅ Checklist created successfully!");
    } catch (e) {
      print("❌ Error creating checklist: $e");
      throw Exception("Failed to create checklist.");
    }
  }

  /// 🔹 Fetch All Employees
  static Future<List<Map<String, dynamic>>> fetchEmployees() async {
    try {
      final records = await pb.collection('users').getFullList(
            fields:
                "id,name,role,branch,phone,email,address,start_date,warnings,requests,emergency_contact_name,emergency_contact_phone,certifications",
          );
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("❌ Error fetching employees: $e");
      return [];
    }
  }
}
