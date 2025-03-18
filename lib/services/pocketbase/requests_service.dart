import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/utils/constants.dart'; // ✅ Import the constants file
import 'package:http/http.dart' as http;

class RequestsService {
  static final String collectionUrl =
      "$pocketBaseUrl/api/collections/requests/records";

  /// 🔹 Fetch all requests (Managers see all, Employees see their own)
  static Future<List<Map<String, dynamic>>> fetchRequests(
      {bool isManager = false}) async {
    try {
      String? userId = AuthService.getLoggedInUserId();
      if (userId == null) throw Exception("❌ User not logged in");

      // ✅ Employees only see their own requests, managers see all requests
      String queryString = isManager ? "" : "?filter=(submitted_by='$userId')";

      final records = await BaseService.fetchAll("$collectionUrl$queryString");
      print("✅ Fetched ${records.length} requests");
      return records;
    } catch (e) {
      print("❌ Error fetching requests: $e");
      return [];
    }
  }

  /// 🔹 Submit a new request (Supports Meeting Requests & Attachments)
  static Future<bool> submitRequest({
    required String requestType,
    required String description,
    DateTime? meetingDate,
    DateTime? meetingStart,
    DateTime? meetingEnd,
    FilePickerResult? attachment,
  }) async {
    try {
      // ✅ Get the logged-in user ID
      String? userId = AuthService.getLoggedInUserId();
      if (userId == null)
        throw Exception("❌ Cannot submit request: User ID is null.");

      print("🔍 Submitting request with user ID: $userId");

      // ✅ Prepare request data
      Map<String, dynamic> requestData = {
        "request_type": requestType,
        "description": description,
        "status": "Pending",
        "submitted_by": userId, // Ensure valid user ID in PocketBase
        "meeting_date": meetingDate?.toIso8601String(),
        "meeting_start": meetingStart?.toIso8601String(),
        "meeting_end": meetingEnd?.toIso8601String(),
      };

      String? requestId = await BaseService.create(collectionUrl, requestData);
      if (requestId == null)
        throw Exception("❌ Failed to create request record.");

      // ✅ Upload the file if an attachment exists
      if (attachment != null) {
        Uint8List fileBytes = attachment.files.single.bytes!;
        String fileName = attachment.files.single.name;

        final multipartFile = http.MultipartFile.fromBytes(
          'attachment',
          fileBytes,
          filename: fileName,
        );

        await BaseService.update(collectionUrl, requestId, {},
            files: [multipartFile]);
      }

      print("✅ Request successfully submitted with ID: $requestId");
      return true;
    } catch (e) {
      print("❌ Error submitting request: $e");
      return false;
    }
  }

  /// 🔹 Approve or Deny a Request (Managers Only)
  static Future<bool> updateRequestStatus({
    required String requestId,
    required String status,
    required String approvedBy,
    String? managerComment,
  }) async {
    try {
      await BaseService.update(collectionUrl, requestId, {
        "status": status,
        "approved_by": approvedBy,
        if (managerComment != null) "manager_comment": managerComment,
      });

      print("✅ Request $requestId updated to $status");
      return true;
    } catch (e) {
      print("❌ Error updating request status: $e");
      return false;
    }
  }

  /// 🔹 Delete a Request (Admins or Managers)
  static Future<bool> deleteRequest(String requestId) async {
    try {
      bool success = await BaseService.delete(collectionUrl, requestId);
      if (success) {
        print("✅ Request $requestId deleted successfully.");
        return true;
      } else {
        throw Exception("❌ Failed to delete request.");
      }
    } catch (e) {
      print("❌ Error deleting request: $e");
      return false;
    }
  }
}
