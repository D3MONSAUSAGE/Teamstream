import 'package:pocketbase/pocketbase.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/utils/constants.dart'; // Add this import

class SchedulesService {
  final PocketBase pb;

  SchedulesService(this.pb) {
    // Debug: Verify the PocketBase instance URL
    print("🔍 SchedulesService initialized with PocketBase URL: ${pb.baseUrl}");
    if (pb.baseUrl != pocketBaseUrl) {
      print(
          "⚠️ Warning: PocketBase URL does not match constants.dart pocketBaseUrl ($pocketBaseUrl)");
    }
  }

  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    try {
      final result = await pb.collection('users').getList(
            filter: 'role != "Admin"',
            fields: 'id,name,role',
          );
      final employees = result.items.map((item) => item.toJson()).toList();
      print('🔍 Fetched Employees: $employees');
      return employees;
    } catch (e) {
      print('❌ Error fetching employees: $e');
      throw Exception('Failed to fetch employees');
    }
  }

  Future<List<Map<String, dynamic>>> fetchShifts(
      {String? userId, DateTime? start, DateTime? end}) async {
    try {
      String filter = userId != null ? 'user = "$userId"' : '';
      if (start != null && end != null) {
        filter +=
            '${filter.isNotEmpty ? ' && ' : ''}start_time >= "${start.toIso8601String()}" && start_time <= "${end.toIso8601String()}"';
      }
      final result = await pb.collection('schedules').getList(
            filter: filter.isNotEmpty ? filter : null,
            sort: 'start_time',
            expand: 'user',
          );
      return result.items.map((item) => item.toJson()).toList();
    } catch (e) {
      print('❌ Error fetching shifts: $e');
      throw Exception('Failed to fetch shifts');
    }
  }

  Future<void> createShift({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      final managerId =
          pb.authStore.model?.id ?? AuthService.getLoggedInUserId();
      print('🔍 Creating shift - User ID: $userId, Manager ID: $managerId');
      if (managerId == null) throw Exception('Manager not authenticated');
      if (userId.isEmpty) throw Exception('User ID cannot be empty');
      final body = {
        'user': userId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'notes': notes ?? '',
        'created_by': managerId,
      };
      print('🔍 Sending shift body to PocketBase: $body');
      await pb.collection('schedules').create(body: body);
      print('✅ Shift created successfully');
    } catch (e) {
      print('❌ Error creating shift: $e');
      throw Exception('Failed to create shift');
    }
  }

  Future<void> deleteShift(String shiftId) async {
    try {
      await pb.collection('schedules').delete(shiftId);
      print('✅ Shift $shiftId deleted');
    } catch (e) {
      print('❌ Error deleting shift: $e');
      throw Exception('Failed to delete shift');
    }
  }
}
