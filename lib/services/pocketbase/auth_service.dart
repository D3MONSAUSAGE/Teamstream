import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:teamstream/utils/constants.dart';
import 'package:teamstream/services/pocketbase/role_service.dart';

class AuthService {
  static String? loggedInUserId;
  static String? loggedInUserRole;
  static String? authToken;
  static PocketBase? _pb;

  static void init(PocketBase pb) {
    _pb = pb;
  }

  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    if (_pb == null) {
      throw Exception('AuthService not initialized with PocketBase');
    }
    try {
      final url =
          Uri.parse("$pocketBaseUrl/api/collections/users/auth-with-password");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"identity": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('record') && data.containsKey('token')) {
          loggedInUserId = data["record"]["id"];
          loggedInUserRole = data["record"]["role"] ?? "User";
          authToken = data["token"];
          _pb!.authStore.save(authToken!, RecordModel.fromJson(data["record"]));
          RoleService.setUserRole(loggedInUserRole!);
          print(
              "✅ Logged in: User ID: $loggedInUserId, Role: $loggedInUserRole, Token: $authToken");
          return {
            "userId": loggedInUserId,
            "role": loggedInUserRole,
            "token": authToken,
          };
        } else {
          throw Exception("Login response is missing user record or token.");
        }
      } else {
        throw Exception("Login failed: ${response.body}");
      }
    } catch (e) {
      print("❌ AuthService.login() error: $e");
      return null;
    }
  }

  static String? getLoggedInUserId() => loggedInUserId;
  static String? getToken() => authToken;
  static String? getRole() => loggedInUserRole;

  static void setLoggedInUser(String userId, String role, {String? token}) {
    if (_pb == null) {
      throw Exception('AuthService not initialized with PocketBase');
    }
    loggedInUserId = userId;
    loggedInUserRole = role;
    authToken = token;
    if (token != null) {
      final recordData = {"id": userId, "role": role};
      _pb!.authStore.save(token, RecordModel.fromJson(recordData));
    }
    print("✅ User set: ID: $userId, Role: $role, Token: $token");
  }

  static void clearLoggedInUser() {
    if (_pb == null) {
      throw Exception('AuthService not initialized with PocketBase');
    }
    loggedInUserId = null;
    loggedInUserRole = null;
    authToken = null;
    _pb!.authStore.clear();
    print("✅ User logged out successfully.");
  }
}
