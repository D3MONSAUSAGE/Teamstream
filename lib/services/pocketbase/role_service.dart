class RoleService {
  static const String cook = "Cook";
  static const String cashier = "Cashier";
  static const String shiftLeader = "Shift Leader";
  static const String kitchenLeader = "Kitchen Leader";
  static const String hospitalityManager = "Hospitality Manager";
  static const String branchManager = "Branch Manager";
  static const String admin = "Admin";

  static String? currentUserRole;

  /// 🔹 Set the current user's role
  static void setUserRole(String role) {
    currentUserRole = role;
    print("✅ Role set in RoleService: $currentUserRole"); // Debug log
  }

  /// 🔹 Check if the user is a manager
  static bool isManager() {
    return currentUserRole == hospitalityManager ||
        currentUserRole == branchManager ||
        currentUserRole == admin;
  }

  /// 🔹 Check if the user is a leader
  static bool isLeader() {
    return currentUserRole == shiftLeader || currentUserRole == kitchenLeader;
  }

  /// 🔹 Check if the user is an admin
  static bool isAdmin() {
    return currentUserRole == admin;
  }

  /// 🔹 Check if the user can create checklists
  static bool canCreateChecklists() {
    return isLeader() || isManager() || isAdmin();
  }
}
