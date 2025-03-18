import 'package:teamstream/services/pocketbase/auth_service.dart';

class RoleService {
  // Define all roles as constants
  static const String cashier = "Cashier";
  static const String cook = "Cook";
  static const String shiftLeader = "Shift Leader";
  static const String kitchenLeader = "Kitchen Leader";
  static const String hospitalityManager = "Hospitality Manager";
  static const String branchManager = "Branch Manager";
  static const String admin = "Admin";

  // List of all roles for validation or dropdowns
  static const List<String> allRoles = [
    cashier,
    cook,
    shiftLeader,
    kitchenLeader,
    hospitalityManager,
    branchManager,
    admin,
  ];

  /// 🔹 Set the current user's role
  static void setUserRole(String role) {
    // Validate the role before setting
    if (!allRoles.contains(role)) {
      throw Exception("Invalid role: $role. Must be one of $allRoles");
    }
    AuthService.setLoggedInUser(
      AuthService.getLoggedInUserId() ?? "",
      role,
      token: AuthService.getToken(),
    );
    print("✅ Role set in RoleService: $role");
  }

  /// 🔹 Check if the user is a manager
  static bool isManager() {
    final role = AuthService.getRole();
    return role == hospitalityManager || role == branchManager || role == admin;
  }

  /// 🔹 Check if the user is a leader
  static bool isLeader() {
    final role = AuthService.getRole();
    return role == shiftLeader || role == kitchenLeader;
  }

  /// 🔹 Check if the user is an admin
  static bool isAdmin() {
    final role = AuthService.getRole();
    return role == admin;
  }

  /// 🔹 Check if the user can create checklists
  static bool canCreateChecklists() {
    final role = AuthService.getRole();
    if (role == null) {
      print("❌ No role found for current user");
      return false;
    }
    bool canCreate = isLeader() || isManager() || isAdmin();
    print("🛠️ Checking create permission for role '$role': $canCreate");
    return canCreate;
  }

  /// 🔹 Check if the user can execute checklists
  static bool canExecuteChecklists() {
    final role = AuthService.getRole();
    if (role == null) {
      print("❌ No role found for current user");
      return false;
    }
    // All roles can execute checklists
    bool canExecute = allRoles.contains(role);
    print("🛠️ Checking execute permission for role '$role': $canExecute");
    return canExecute;
  }

  /// 🔹 Check if the user can verify checklists
  static bool canVerifyChecklists() {
    final role = AuthService.getRole();
    if (role == null) {
      print("❌ No role found for current user");
      return false;
    }
    // Only Shift Leader and above can verify
    bool canVerify = role == shiftLeader ||
        role == kitchenLeader ||
        role == hospitalityManager ||
        role == branchManager ||
        role == admin;
    print("🛠️ Checking verify permission for role '$role': $canVerify");
    return canVerify;
  }
}
