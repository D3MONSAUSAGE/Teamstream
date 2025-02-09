import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

class PocketBaseService {
  static final PocketBase pb =
      PocketBase('http://127.0.0.1:8090'); // ✅ Update with your PocketBase URL

  /// 🔹 Get the Current Logged-in User ID
  static Future<String> getCurrentUserId() async {
    return pb.authStore.model.id;
  }

  /// 🔹 Fetch Current User Data
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final userId = await getCurrentUserId();
      final record = await pb.collection('users').getOne(userId);
      return record.toJson();
    } catch (e) {
      print("Error fetching user data: $e");
      throw Exception("Failed to fetch user data.");
    }
  }

  /// 🔹 User Login
  static Future<bool> login(String email, String password) async {
    try {
      final authResponse =
          await pb.collection('users').authWithPassword(email, password);
      return authResponse.token.isNotEmpty;
    } catch (e) {
      print("Login failed: $e");
      return false;
    }
  }

  /// 🔹 Fetch Checklists
  /// 🔹 Fetch Active Checklists
  static Future<List<Map<String, dynamic>>> fetchChecklists() async {
    try {
      final records = await pb.collection('checklists').getFullList(
            filter: "completed = false", // ✅ Only fetch incomplete checklists
          );
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("❌ Error fetching checklists: $e");
      return [];
    }
  }

  /// 🔹 Submit Employee Request
  static Future<void> submitRequest({
    required String requestType,
    required String reason,
    required DateTime date,
  }) async {
    try {
      String userId = await getCurrentUserId();
      await pb.collection('requests').create(body: {
        "employee_id": userId,
        "request_type": requestType,
        "reason": reason,
        "date": date.toIso8601String(),
        "status": "Pending",
      });
    } catch (e) {
      print("Error submitting request: $e");
      throw Exception("Failed to submit request.");
    }
  }

  /// 🔹 Fetch User Requests
  static Future<List<Map<String, dynamic>>> fetchMyRequests() async {
    try {
      String userId = await getCurrentUserId();
      final records = await pb.collection('requests').getFullList(
            filter: "employee_id = '$userId'",
          );
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("Error fetching user requests: $e");
      return [];
    }
  }

  /// 🔹 Fetch All Requests (For Managers/Admins)
  static Future<List<Map<String, dynamic>>> fetchAllRequests() async {
    try {
      final records = await pb.collection('requests').getFullList();
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("Error fetching all requests: $e");
      return [];
    }
  }

  /// 🔹 Approve or Reject a Request
  static Future<void> updateRequestStatus(
      String requestId, String status) async {
    try {
      await pb.collection('requests').update(requestId, body: {
        "status": status,
      });
    } catch (e) {
      print("Error updating request status: $e");
    }
  }

  /// 🔹 Fetch Assigned Schedules
  static Future<List<Map<String, dynamic>>> fetchAssignedSchedules() async {
    try {
      final records = await pb.collection('schedules').getFullList();
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("Error fetching assigned schedules: $e");
      return [];
    }
  }

  /// 🔹 Fetch Shift Drop Requests
  static Future<List<Map<String, dynamic>>> fetchShiftDropRequests() async {
    try {
      final records = await pb.collection('shift_drops').getFullList(
            filter: "status = 'Available'",
          );
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("Error fetching shift drop requests: $e");
      return [];
    }
  }

  /// 🔹 Drop a Shift
  static Future<void> dropShift(String position, DateTime date,
      DateTime startTime, DateTime endTime) async {
    try {
      String userId = await getCurrentUserId();
      await pb.collection('shift_drops').create(body: {
        "employee_id": userId,
        "position": position,
        "date": date.toIso8601String(),
        "start_time": startTime.toIso8601String(),
        "end_time": endTime.toIso8601String(),
        "status": "Available",
        "claimed_by": null,
      });
    } catch (e) {
      print("Error dropping shift: $e");
    }
  }

  /// 🔹 Claim a Shift
  static Future<void> claimShift(String shiftId) async {
    try {
      String userId = await getCurrentUserId();
      await pb.collection('shift_drops').update(shiftId, body: {
        "status": "Claimed",
        "claimed_by": userId,
      });
    } catch (e) {
      print("Error claiming shift: $e");
    }
  }

  /// 🔹 Fetch Claimed Shifts
  static Future<List<Map<String, dynamic>>> fetchClaimedShifts() async {
    try {
      String userId = await getCurrentUserId();
      final records = await pb.collection('shift_drops').getFullList(
            filter: "claimed_by = '$userId'",
          );
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("Error fetching claimed shifts: $e");
      return [];
    }
  }

  /// 🔹 Fetch Invoices
  static Future<List<Map<String, dynamic>>> fetchInvoices() async {
    try {
      final records = await pb.collection('invoices').getFullList();
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("Error fetching invoices: $e");
      return [];
    }
  }

  /// 🔹 Upload Invoice
  static Future<bool> uploadInvoice(PlatformFile file) async {
    try {
      await pb.collection('invoices').create(
        body: {
          "vendor_name": "Unknown Vendor",
          "date": DateTime.now().toIso8601String(),
        },
        files: [
          http.MultipartFile.fromBytes('file', file.bytes!,
              filename: file.name),
        ],
      );
      return true;
    } catch (e) {
      print("Error uploading invoice: $e");
      return false;
    }
  }

  /// 🔹 Download Invoice
  static void downloadInvoice(String fileUrl) {
    try {
      launchUrl(Uri.parse(fileUrl));
    } catch (e) {
      print("Error downloading invoice: $e");
    }
  }

  /// 🔹 Submit Checklist Data
  /// 🔹 Submit Checklist Data
  static Future<void> submitChecklistData(
      String checklistId, List<Map<String, dynamic>> tasks) async {
    try {
      // Convert tasks list to JSON format
      List<Map<String, dynamic>> formattedTasks = tasks.map((task) {
        return {"name": task["name"], "completed": task["completed"] ?? false};
      }).toList();

      await pb.collection('checklists').update(checklistId, body: {
        "tasks": formattedTasks, // ✅ Save updated tasks
        "completed": true, // ✅ Mark checklist as completed
        "executed_at":
            DateTime.now().toIso8601String() // ✅ Store execution timestamp
      });

      print("✅ Checklist submitted successfully!");
    } catch (e) {
      print("❌ Error submitting checklist: $e");
      throw Exception("Failed to submit checklist.");
    }
  }

  /// 🔹 Update Profile Picture (Fixed)
  static Future<void> updateProfilePicture(File file) async {
    try {
      String userId = await getCurrentUserId();
      final multipartFile =
          await http.MultipartFile.fromPath('file', file.path);
      await pb.collection('users').update(userId, files: [multipartFile]);
    } catch (e) {
      print("Error updating profile picture: $e");
    }
  }

  /// 🔹 Update User Profile (Fixed)
  static Future<void> updateUserProfile(
      {required String name, required String email}) async {
    try {
      String userId = await getCurrentUserId();
      await pb.collection('users').update(userId, body: {
        "name": name,
        "email": email,
      });
    } catch (e) {
      print("Error updating user profile: $e");
    }
  }

  /// 🔹 Create a Checklist
  /// 🔹 Create a Checklist
  static Future<void> createChecklist(
    String title,
    String description,
    String shift,
    String startTime, // ✅ Now a String
    String endTime, // ✅ Now a String
    List<String> tasks,
    String area,
  ) async {
    try {
      await pb.collection('checklists').create(body: {
        "title": title,
        "description": description,
        "shift": shift,
        "start_time": startTime, // ✅ Directly stores as String
        "end_time": endTime, // ✅ Directly stores as String
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
