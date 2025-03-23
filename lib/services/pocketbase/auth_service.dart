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

          // Fetch the full user record to include the email field
          final userUrl = Uri.parse(
              "$pocketBaseUrl/api/collections/users/records/$loggedInUserId?fields=id,role,email");
          final userResponse = await http.get(
            userUrl,
            headers: {
              "Authorization": "Bearer $authToken",
            },
          );

          if (userResponse.statusCode == 200) {
            final userData = jsonDecode(userResponse.body);
            // Debug: Print the user data to verify the email field
            print("User data after login: $userData");
            // Update the auth store with the full user record
            _pb!.authStore.save(authToken!, RecordModel.fromJson(userData));
            // Debug: Print the auth store model to verify the email field
            print("Auth store model after login: ${_pb!.authStore.model.data}");
          } else {
            throw Exception("Failed to fetch user email: ${userResponse.body}");
          }

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

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_pb == null) {
      throw Exception('AuthService not initialized with PocketBase');
    }
    try {
      // Fetch the user's email directly using the user ID
      final userId = loggedInUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final userUrl = Uri.parse(
          "$pocketBaseUrl/api/collections/users/records/$userId?fields=email");
      final userResponse = await http.get(
        userUrl,
        headers: {
          "Authorization": "Bearer $authToken",
        },
      );

      if (userResponse.statusCode != 200) {
        throw Exception("Failed to fetch user email: ${userResponse.body}");
      }

      final userData = jsonDecode(userResponse.body);
      final email = userData['email'] as String?;
      if (email == null) {
        throw Exception('User email not found in user record');
      }

      // Verify the current password by attempting to log in
      final loginUrl =
          Uri.parse("$pocketBaseUrl/api/collections/users/auth-with-password");
      final loginResponse = await http.post(
        loginUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"identity": email, "password": currentPassword}),
      );

      if (loginResponse.statusCode != 200) {
        throw Exception('Current password is incorrect: ${loginResponse.body}');
      }

      // If login succeeds, update the password
      final updateUrl =
          Uri.parse("$pocketBaseUrl/api/collections/users/records/$userId");
      final updateResponse = await http.patch(
        updateUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: jsonEncode({
          "oldPassword": currentPassword, // Added oldPassword field
          "password": newPassword,
          "passwordConfirm": newPassword,
        }),
      );

      if (updateResponse.statusCode != 200) {
        throw Exception('Failed to update password: ${updateResponse.body}');
      }

      // Re-authenticate with the new password to update the auth store
      final reauthResponse = await http.post(
        loginUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"identity": email, "password": newPassword}),
      );

      if (reauthResponse.statusCode == 200) {
        final reauthData = jsonDecode(reauthResponse.body);
        if (reauthData.containsKey('record') &&
            reauthData.containsKey('token')) {
          loggedInUserId = reauthData["record"]["id"];
          loggedInUserRole = reauthData["record"]["role"] ?? "User";
          authToken = reauthData["token"];
          _pb!.authStore
              .save(authToken!, RecordModel.fromJson(reauthData["record"]));
          RoleService.setUserRole(loggedInUserRole!);
          print("✅ Re-authenticated after password change");
        } else {
          throw Exception("Re-auth response is missing user record or token.");
        }
      } else {
        throw Exception(
            "Re-auth failed after password change: ${reauthResponse.body}");
      }

      return true;
    } catch (e) {
      print("❌ AuthService.changePassword() error: $e");
      throw Exception('Failed to change password: $e');
    }
  }
}
