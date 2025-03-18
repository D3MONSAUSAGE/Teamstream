import 'dart:typed_data';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';

class MilesService {
  static final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  /// 🔹 Submit a new mileage entry
  static Future<bool> submitMileage({
    required String employeeId,
    required String miles,
    required String comments,
    required String reason,
    required Uint8List image,
    required String payPerMile,
  }) async {
    try {
      final record = await pb.collection('mileage').create(
        body: {
          "employee_id": employeeId,
          "miles": miles,
          "comments": comments,
          "status": "Pending",
          "timestamp": DateTime.now().toIso8601String(),
          "pay_per_mile": payPerMile,
          "reason": reason,
        },
      );

      await pb.collection('mileage').update(record.id, files: [
        MultipartFile.fromBytes('mileage_photo', image,
            filename: 'mileage_proof.jpg')
      ]);

      print("✅ Mileage entry submitted successfully: ${record.id}");
      return true;
    } catch (e) {
      print("❌ Error submitting mileage entry: $e");
      return false;
    }
  }

  /// 🔹 Fetch mileage reports (employees & managers)
  static Future<List<Map<String, dynamic>>> fetchMileageReports(
      {bool isManager = false}) async {
    try {
      String? userId = AuthService.getLoggedInUserId();
      if (userId == null) throw Exception("User not logged in");

      final filter = isManager ? "" : "employee_id = '$userId'";

      final records = await pb.collection('mileage').getFullList(
            filter: filter,
            sort: "-timestamp",
          );

      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("❌ Error fetching mileage reports: $e");
      return [];
    }
  }

  /// 🔹 Approve or Deny Mileage Entry (Managers Only)
  static Future<bool> updateMileageStatus({
    required String entryId,
    required String status,
    required String approvedBy,
    String? managerComment,
  }) async {
    try {
      await pb.collection('mileage').update(entryId, body: {
        "status": status,
        "approved_by": approvedBy,
        if (managerComment != null) "manager_comment": managerComment,
      });

      print("✅ Mileage entry $entryId updated to $status");
      return true;
    } catch (e) {
      print("❌ Error updating mileage status: $e");
      return false;
    }
  }

  /// 🔹 Get Pay Rate Per Mile (Admins Set This)
  static Future<String> getPayRatePerMile() async {
    try {
      final record = await pb.collection('settings').getFirstListItem(
            "setting_name = 'pay_per_mile'",
          );
      return record.data["value"] ?? "0.50"; // Default to $0.50/mile
    } catch (e) {
      print("❌ Error fetching pay rate per mile: $e");
      return "0.50"; // Default value
    }
  }

  /// 🔹 Update Pay Rate Per Mile (Admins Only)
  static Future<bool> updatePayRatePerMile(String newRate) async {
    try {
      await pb.collection('settings').update(
        "pay_per_mile",
        body: {"value": newRate},
      );
      print("✅ Pay rate per mile updated to \$$newRate");
      return true;
    } catch (e) {
      print("❌ Error updating pay rate per mile: $e");
      return false;
    }
  }

  /// 🔹 Fetch all mileage records for managers
  static Future<List<Map<String, dynamic>>> fetchAllMileageRecords() async {
    try {
      final records = await pb.collection('mileage').getFullList(
            sort: "-timestamp",
          );
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("❌ Error fetching all mileage records: $e");
      return [];
    }
  }

  /// 🔹 Fetch mileage records for a specific employee
  static Future<List<Map<String, dynamic>>> fetchEmployeeMileageRecords(
      String employeeId) async {
    try {
      final records = await pb.collection('mileage').getFullList(
            filter: "employee_id = '$employeeId'",
            sort: "-timestamp",
          );
      return records.map((record) => record.toJson()).toList();
    } catch (e) {
      print("❌ Error fetching employee mileage records: $e");
      return [];
    }
  }

  /// 🔹 Fetch mileage data for reporting (Total miles paid over time)
  static Future<List<Map<String, dynamic>>> fetchMilesData() async {
    try {
      final records = await pb.collection('mileage').getFullList(
            sort: "-timestamp",
          );

      return records.map((record) {
        return {
          "date": record.data["timestamp"],
          "miles": double.tryParse(record.data["miles"].toString()) ?? 0.0,
          "total_paid": (double.tryParse(record.data["miles"].toString()) ??
                  0.0) *
              (double.tryParse(record.data["pay_per_mile"].toString()) ?? 0.0),
        };
      }).toList();
    } catch (e) {
      print("❌ Error fetching mileage data: $e");
      return [];
    }
  }
}
