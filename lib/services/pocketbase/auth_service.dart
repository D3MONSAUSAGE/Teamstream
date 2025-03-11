import 'package:pocketbase/pocketbase.dart';
import 'package:teamstream/utils/constants.dart'; // Import the constants file

class AuthService {
  static String? _loggedInUserId;
  static String? _loggedInUserRole;

  /// 🔹 Get the logged-in user's ID
  static String? getLoggedInUserId() {
    return _loggedInUserId;
  }

  /// 🔹 Get the logged-in user's role
  static String? getUserRole() {
    return _loggedInUserRole;
  }

  /// 🔹 Set the logged-in user's ID & Role
  static void setLoggedInUser(String userId, String role) {
    _loggedInUserId = userId;
    _loggedInUserRole = role;
  }

  /// 🔹 Clear the stored user data when logging out
  static void clearLoggedInUser() {
    _loggedInUserId = null;
    _loggedInUserRole = null;
    print("✅ Logged-in user data cleared.");
  }

  /// 🔹 Authenticate and log in the user
  static Future<bool> login(String email, String password) async {
    try {
      // Use the pocketBaseUrl constant from constants.dart
      final pb = PocketBase(pocketBaseUrl);

      final authResponse =
          await pb.collection('users').authWithPassword(email, password);

      String userId = authResponse.record.id;
      String userRole =
          authResponse.record.data["role"]; // Fetch role from record data

      setLoggedInUser(userId, userRole); // ✅ Store user ID & Role

      print("✅ Successfully logged in. User ID: $userId | Role: $userRole");
      return true;
    } catch (e) {
      print("❌ Login failed: $e");
      return false;
    }
  }
}
