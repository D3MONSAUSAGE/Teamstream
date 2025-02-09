import 'package:pocketbase/pocketbase.dart';

class AuthService {
  static final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  static Future<bool> login(String email, String password) async {
    try {
      await pb.collection('users').authWithPassword(email, password);
      return true;
    } catch (e) {
      print("Login failed: $e");
      return false;
    }
  }

  static Future<void> logout() async {
    pb.authStore.clear();
  }

  static Future<RecordModel?> getUser() async {
    return pb.authStore.model;
  }
}
