import 'package:pocketbase/pocketbase.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';

class AuthService {
  static String? _loggedInUserId;

  /// 🔹 Get the logged-in user's ID
  static String? getLoggedInUserId() {
    return _loggedInUserId;
  }

  /// 🔹 Set the logged-in user's ID
  static void setLoggedInUser(String userId) {
    _loggedInUserId = userId;
  }

  /// 🔹 Clear the stored user ID when logging out
  static void clearLoggedInUser() {
    _loggedInUserId = null;
    print("✅ Logged-in user ID cleared.");
  }
}

/// 🔹 Authenticate and log in the user
Future<bool> loginUser(String email, String password) async {
  try {
    final pb = PocketBase(BaseService.baseUrl);
    final authResponse =
        await pb.collection('users').authWithPassword(email, password);

    AuthService._loggedInUserId = authResponse.record.id; // Store user ID
    print("✅ Logged in user ID: ${AuthService._loggedInUserId}");
    return true;
  } catch (e) {
    print("❌ Login failed: $e");
    return false;
  }
}
