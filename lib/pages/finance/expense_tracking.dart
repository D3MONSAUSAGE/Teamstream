import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/services/pocketbase/expense_service.dart';

class ExpenseTrackingPage extends StatefulWidget {
  const ExpenseTrackingPage({super.key});

  @override
  ExpenseTrackingPageState createState() => ExpenseTrackingPageState();
}

class ExpenseTrackingPageState extends State<ExpenseTrackingPage> {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadExpenses();
    loadCategories();
  }

  /// 🔹 Load expenses from PocketBase
  void loadExpenses() async {
    List<Map<String, dynamic>> fetchedExpenses =
        await ExpenseService.fetchExpenses();
    setState(() {
      expenses = fetchedExpenses;
      isLoading = false;
    });
  }

  /// 🔹 Load categories from PocketBase
  void loadCategories() async {
    List<Map<String, dynamic>> fetchedCategories =
        await ExpenseService.fetchExpenseCategories();
    setState(() {
      categories = fetchedCategories;
    });
  }

  /// 🔹 Open the add expense dialog
  void _showAddExpenseDialog() {
    TextEditingController amountController = TextEditingController();
    TextEditingController notesController = TextEditingController();
    DateTime? selectedDate;
    String? selectedCategoryId; // Now stores the selected category ID

    void _pickDate() async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (pickedDate != null) {
        setState(() {
          selectedDate = pickedDate;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Expense"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount"),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: Text(selectedDate == null
                      ? "Select Expense Date"
                      : "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}"),
                  leading: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  items: categories
                      .map((category) => DropdownMenuItem<String>(
                            value: category["id"] as String,
                            child: Text(category["name"]),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: "Notes"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty ||
                    selectedDate == null ||
                    selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please fill in all required fields.")),
                  );
                  return;
                }

                double? amount = double.tryParse(amountController.text);
                if (amount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid amount entered.")),
                  );
                  return;
                }

                await ExpenseService.addExpense(
                  amount: amount,
                  categoryId: selectedCategoryId!,
                  date: selectedDate!,
                  notes: notesController.text,
                );

                loadExpenses();
                Navigator.pop(context);
              },
              child: const Text("Add Expense"),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Delete Expense
  void _deleteExpense(String expenseId) async {
    bool success = await ExpenseService.deleteExpense(expenseId);
    if (success) {
      loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Expense Tracking")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
              ? const Center(child: Text("No expenses found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    var expense = expenses[index];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.monetization_on,
                            color: Colors.green),
                        title: Text("\$${expense["amount"]}",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(expense["date"]))}",
                            ),
                            Text("Category: ${expense["category"]}"),
                            if (expense["notes"] != null &&
                                expense["notes"].isNotEmpty)
                              Text("Notes: ${expense["notes"]}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: "Delete Expense",
                          onPressed: () => _deleteExpense(expense["id"]),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
