import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;

class MyAccountService {
  final PocketBase pb;

  MyAccountService(this.pb);

  // Fetch the logged-in user's profile data
  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final userId = pb.authStore.model.id; // Get the logged-in user's ID
      final record = await pb.collection('users').getOne(userId);
      return record.toJson();
    } catch (e) {
      print('Error fetching user profile: $e');
      throw Exception('Failed to fetch user profile');
    }
  }

  // Update a specific field in the user's profile
  Future<void> updateUserProfileField(String field, dynamic value) async {
    try {
      final userId = pb.authStore.model.id; // Get the logged-in user's ID
      await pb.collection('users').update(userId, body: {field: value});
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile');
    }
  }

  // Update the user's profile picture
  Future<void> updateProfilePicture(String filePath) async {
    try {
      final userId = pb.authStore.model.id; // Get the logged-in user's ID
      final file =
          await http.MultipartFile.fromPath('profile_picture', filePath);

      await pb.collection('users').update(
        userId,
        files: [file],
      );
    } catch (e) {
      print('Error updating profile picture: $e');
      throw Exception('Failed to update profile picture');
    }
  }

  // Change the user's password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      await pb.collection('users').update(
        pb.authStore.model.id,
        body: {
          'currentPassword': currentPassword,
          'password': newPassword,
          'passwordConfirm': newPassword,
        },
      );
    } catch (e) {
      print('Error changing password: $e');
      throw Exception('Failed to change password');
    }
  }
}
