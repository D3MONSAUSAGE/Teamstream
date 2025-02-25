import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:http/http.dart' as http;

class RequestsService {
  static const String collectionName = "requests";

  /// 🔹 Submit a new request (Supports Meeting Requests)
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

      if (userId == null) {
        throw Exception("❌ Cannot submit request: User ID is null.");
      }

      print("🔍 Submitting request with user ID: $userId");

      // ✅ Create request record in PocketBase
      Map<String, dynamic> requestData = {
        "request_type": requestType,
        "description": description,
        "status": "Pending",
        "submitted_by": userId, // ✅ Ensure this ID is valid in PocketBase
        "meeting_date": meetingDate?.toIso8601String(),
        "meeting_start": meetingStart?.toIso8601String(),
        "meeting_end": meetingEnd?.toIso8601String(),
      };

      String? requestId = await BaseService.create(collectionName, requestData);

      if (requestId == null) {
        throw Exception("❌ Failed to create request record.");
      }

      // ✅ Upload the file if provided
      if (attachment != null) {
        Uint8List fileBytes = attachment.files.single.bytes!;
        String fileName = attachment.files.single.name;

        final multipartFile = http.MultipartFile.fromBytes(
          'attachment',
          fileBytes,
          filename: fileName,
        );

        await BaseService.update(collectionName, requestId, {},
            files: [multipartFile]);
      }

      print("✅ Request successfully submitted with ID: $requestId");
      return true;
    } catch (e) {
      print("❌ Error submitting request: $e");
      return false;
    }
  }
}
