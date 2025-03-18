import 'package:geolocator/geolocator.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';
import 'package:teamstream/services/pocketbase/role_service.dart';
import 'package:teamstream/utils/constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ClockInService {
  static const String clockInsCollection = "clock_ins";
  static String? _currentClockInRecordId;

  static String? get currentClockInRecordId => _currentClockInRecordId;

  static Future<Position> getCurrentPosition() async {
    try {
      if (!kIsWeb) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception(
              "Location services are disabled. Please enable them in your device settings.");
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
              "Location permissions are denied. Please allow location access to continue.");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            "Location permissions are permanently denied. Please enable them in your browser or device settings.");
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print("❌ Error in getCurrentPosition: $e");
      if (kIsWeb) {
        throw Exception(
          "Failed to get location. Please ensure location services are enabled in your browser and you have granted permission. Error: $e",
        );
      } else {
        throw Exception(
          "Failed to get location. Please ensure location services are enabled and permissions are granted. Error: $e",
        );
      }
    }
  }

  static Future<void> clockIn(String code,
      {required Function(String, double, double, DateTime) onSuccess}) async {
    try {
      final userId = AuthService.getLoggedInUserId();
      final userRole = AuthService.getRole();

      if (userId == null || userRole == null) {
        throw Exception("User not authenticated");
      }

      if (!RoleService.isAdmin()) {
        throw Exception("Only admins can clock in");
      }

      final pbUser = await BaseService.fetchOne('users', userId);
      final userCode = pbUser?['clock_in_code'] as String?;
      if (userCode == null || userCode != code) {
        throw Exception("Invalid clock-in code");
      }

      final position = await getCurrentPosition();
      final latitude = position.latitude;
      final longitude = position.longitude;
      final clockInTime = DateTime.now().toLocal(); // Use local time
      print(
          "🔍 Clock-in time generated: $clockInTime (Local: ${clockInTime}, UTC: ${clockInTime.toUtc()})");

      final recordData = {
        'user': userId,
        'time': clockInTime.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'code': code,
      };
      final recordId = await BaseService.create(
        clockInsCollection,
        recordData,
      );

      if (recordId == null || recordId.isEmpty) {
        throw Exception(
            "Failed to create clock-in record: No valid ID returned");
      }

      _currentClockInRecordId = recordId;

      print(
          "✅ Clock-in successful: User $userId at $latitude, $longitude, time stored: ${recordData['time']}");

      onSuccess(recordId, latitude, longitude, clockInTime);
    } catch (e) {
      print("❌ Error in clockIn(): $e");
      rethrow;
    }
  }

  static Future<void> clockOut(String code,
      {required Function(String, double, double) onSuccess}) async {
    try {
      final userId = AuthService.getLoggedInUserId();
      final userRole = AuthService.getRole();

      if (userId == null || userRole == null) {
        throw Exception("User not authenticated");
      }

      if (!RoleService.isAdmin()) {
        throw Exception("Only admins can clock out");
      }

      final pbUser = await BaseService.fetchOne('users', userId);
      final userCode = pbUser?['clock_in_code'] as String?;
      if (userCode == null || userCode != code) {
        throw Exception("Invalid clock-out code");
      }

      if (_currentClockInRecordId == null) {
        throw Exception(
            "No active clock-in record found. Please clock in first.");
      }

      final position = await getCurrentPosition();
      final latitude = position.latitude;
      final longitude = position.longitude;
      final clockOutTime = DateTime.now().toLocal(); // Use local time
      print(
          "🔍 Clock-out time generated: $clockOutTime (Local: ${clockOutTime}, UTC: ${clockOutTime.toUtc()})");

      final recordData = {
        'clock_out_time': clockOutTime.toIso8601String(),
        'clock_out_latitude': latitude,
        'clock_out_longitude': longitude,
      };
      await BaseService.update(
        clockInsCollection,
        _currentClockInRecordId!,
        recordData,
      );

      print(
          "✅ Clock-out successful: User $userId at $latitude, $longitude, time stored: ${recordData['clock_out_time']}");

      onSuccess(_currentClockInRecordId!, latitude, longitude);

      _currentClockInRecordId = null;
    } catch (e) {
      print("❌ Error in clockOut(): $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRecentClockRecords() async {
    try {
      final userId = AuthService.getLoggedInUserId();
      if (userId == null) {
        throw Exception("User not authenticated");
      }

      final DateTime past24Hours =
          DateTime.now().toLocal().subtract(const Duration(hours: 24));
      final result = await BaseService.fetchList(
        clockInsCollection,
        filter:
            'user = "$userId" && time >= "${past24Hours.toIso8601String()}"',
        sort: '-time',
      );

      print("🔍 Fetched recent clock records: $result");
      return result;
    } catch (e) {
      print("❌ Error fetching recent clock records: $e");
      throw Exception("Failed to fetch recent clock records: $e");
    }
  }
}
