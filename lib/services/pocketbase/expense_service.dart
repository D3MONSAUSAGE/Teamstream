import 'package:teamstream/services/pocketbase/base_service.dart';

class ExpenseService {
  static const String collectionName = "expenses";
  static const String categoriesCollection = "expense_categories";

  /// 🔹 Fetch Expense Categories (For Dropdown Selection)
  static Future<List<Map<String, dynamic>>> fetchExpenseCategories() async {
    try {
      List<Map<String, dynamic>> categories =
          await BaseService.fetchAll(categoriesCollection);
      print("✅ Fetched Expense Categories: $categories");
      return categories;
    } catch (e) {
      print("❌ Error fetching expense categories: $e");
      return [];
    }
  }

  /// 🔹 Add a new expense
  static Future<bool> addExpense({
    required double amount,
    required String categoryId, // ✅ Now storing the relation ID
    required DateTime date,
    String? notes,
  }) async {
    try {
      // ✅ Prepare Expense Data
      Map<String, dynamic> expenseData = {
        "amount": amount,
        "category": categoryId, // ✅ Linked to `expense_categories`
        "date": date.toIso8601String(),
        "notes": notes ?? "",
      };

      // ✅ Create Expense in PocketBase
      final record = await BaseService.create(collectionName, expenseData);

      if (record != null) {
        print("✅ Expense added successfully!");
        return true;
      } else {
        throw Exception("❌ Failed to create expense record.");
      }
    } catch (e) {
      print("❌ Error adding expense: $e");
      return false;
    }
  }

  /// 🔹 Fetch all expenses
  static Future<List<Map<String, dynamic>>> fetchExpenses() async {
    try {
      List<Map<String, dynamic>> expenses =
          await BaseService.fetchAll(collectionName);

      print("✅ Fetched Expenses: $expenses");
      return expenses;
    } catch (e) {
      print("❌ Error fetching expenses: $e");
      return [];
    }
  }

  /// 🔹 Fetch a specific expense by ID
  static Future<Map<String, dynamic>?> fetchExpenseById(
      String expenseId) async {
    try {
      return await BaseService.fetchOne(collectionName, expenseId);
    } catch (e) {
      print("❌ Error fetching expense $expenseId: $e");
      return null;
    }
  }

  /// 🔹 Update an existing expense
  static Future<bool> updateExpense(
      String expenseId, Map<String, dynamic> updatedData) async {
    try {
      bool success =
          await BaseService.update(collectionName, expenseId, updatedData);
      if (success) {
        print("✅ Expense $expenseId updated successfully.");
      }
      return success;
    } catch (e) {
      print("❌ Error updating expense $expenseId: $e");
      return false;
    }
  }

  /// 🔹 Delete an expense
  static Future<bool> deleteExpense(String expenseId) async {
    try {
      bool success = await BaseService.delete(collectionName, expenseId);
      if (success) {
        print("✅ Expense $expenseId deleted successfully.");
      }
      return success;
    } catch (e) {
      print("❌ Error deleting expense $expenseId: $e");
      return false;
    }
  }
}
