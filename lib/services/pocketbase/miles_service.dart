import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';
import 'dart:typed_data';

class MilesService {
  // Submit a mileage record
  static Future<bool> submitMileage({
    required String employeeId,
    required String miles,
    required String comments,
    required String reason,
    required Uint8List image,
    required String payPerMile,
  }) async {
    try {
      final data = {
        'employee': employeeId,
        'miles': miles,
        'comments': comments,
        'reason': reason,
        'pay_per_mile': payPerMile,
        'total_pay':
            (double.parse(miles) * double.parse(payPerMile)).toString(),
        'status': 'PENDING', // Default status for new submissions
      };

      final files = [image];
      final recordId = await BaseService.create('miles', data, files: files);

      return recordId != null;
    } catch (e) {
      print('❌ MilesService.submitMileage() error: $e');
      rethrow;
    }
  }

  // Fetch the global pay rate per mile from the settings collection
  static Future<String> fetchPayRate() async {
    try {
      final settings = await BaseService.fetchList(
        'settings',
        perPage: 1, // We only expect one record
      );

      if (settings.isNotEmpty) {
        final payRate = settings.first['pay_per_mile']?.toString() ?? '0.50';
        print('✅ Fetched pay rate: $payRate');
        return payRate;
      } else {
        print('⚠️ No pay rate setting found in settings collection.');
        return '0.50';
      }
    } catch (e) {
      print('❌ MilesService.fetchPayRate() error: $e');
      return '0.50'; // Fallback to default
    }
  }

  // Update the global pay rate per mile in the settings collection
  static Future<bool> updatePayRate(String newRate) async {
    try {
      final role = (AuthService.getRole() ?? '').toLowerCase();
      if (role != 'admin') {
        print('⚠️ User is not an admin, cannot update pay rate setting.');
        return false;
      }

      // Fetch all records to check how many exist
      final settings = await BaseService.fetchList(
        'settings',
        perPage: 10, // Fetch up to 10 records to see if there are multiple
      );

      print('Settings records found: ${settings.length}');
      if (settings.isNotEmpty) {
        // Use the first record to update
        final settingId = settings.first['id'];
        final data = {
          'pay_per_mile': newRate,
          'value': settings.first['value'] ??
              '', // Preserve the existing value field
        };
        print('Updating settings record with ID: $settingId, data: $data');
        final success = await BaseService.update('settings', settingId, data);
        if (success) {
          print('✅ Updated pay rate to $newRate');
        } else {
          print('❌ Failed to update pay rate');
        }
        return success;
      } else {
        // If no setting exists, create a new one
        final data = {
          'pay_per_mile': newRate,
          'value':
              '', // Include the value field as it's in the schema, but leave it empty
        };
        print('Creating new settings record with data: $data');
        final recordId = await BaseService.create('settings', data);
        if (recordId != null) {
          print('✅ Created new settings record with ID: $recordId');
          return true;
        } else {
          print('❌ Failed to create new settings record');
          return false;
        }
      }
    } catch (e) {
      print('❌ MilesService.updatePayRate() error: $e');
      return false;
    }
  }

  // Fetch all mileage reports
  static Future<List<Map<String, dynamic>>> fetchMileageReports() async {
    try {
      final reports = await BaseService.fetchList(
        'miles',
        sort: '-created',
      );

      // Manually fetch expanded data for employee and approved_by
      for (var report in reports) {
        if (report['employee'] != null) {
          final employee =
              await BaseService.fetchOne('users', report['employee']);
          report['expand'] = {
            'employee': employee,
          };
        }
        if (report['approved_by'] != null) {
          final approver =
              await BaseService.fetchOne('users', report['approved_by']);
          report['expand'] = {
            ...report['expand'] ?? {},
            'approved_by': approver,
          };
        }
      }

      return reports;
    } catch (e) {
      print('❌ MilesService.fetchMileageReports() error: $e');
      rethrow;
    }
  }

  // Approve or deny a mileage submission
  static Future<bool> updateMileageStatus(
      String recordId, String status, String approverId) async {
    try {
      final data = {
        'status': status,
        'approved_by': approverId,
      };
      final success = await BaseService.update('miles', recordId, data);
      if (success) {
        print("✅ Mileage record $recordId updated to status: $status");
      } else {
        print("❌ Failed to update mileage record $recordId");
      }
      return success;
    } catch (e) {
      print('❌ MilesService.updateMileageStatus() error: $e');
      rethrow;
    }
  }

  // Update the pay_per_mile for a specific mileage record
  static Future<bool> updateMileagePayRate(
      String recordId, String newPayRate, String miles) async {
    try {
      final data = {
        'pay_per_mile': newPayRate,
        'total_pay':
            (double.parse(miles) * double.parse(newPayRate)).toString(),
      };
      final success = await BaseService.update('miles', recordId, data);
      if (success) {
        print(
            "✅ Mileage record $recordId updated with new pay rate: $newPayRate");
      } else {
        print("❌ Failed to update pay rate for mileage record $recordId");
      }
      return success;
    } catch (e) {
      print('❌ MilesService.updateMileagePayRate() error: $e');
      rethrow;
    }
  }
}
