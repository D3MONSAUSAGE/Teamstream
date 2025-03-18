import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    _loadExpenses();
    _loadCategories();
  }

  Future<void> _loadExpenses() async {
    setState(() => isLoading = true);
    try {
      List<Map<String, dynamic>> fetchedExpenses =
          await ExpenseService.fetchExpenses();
      if (mounted) {
        setState(() {
          expenses = fetchedExpenses;
          isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error loading expenses: $e', isError: true);
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      List<Map<String, dynamic>> fetchedCategories =
          await ExpenseService.fetchExpenseCategories();
      if (mounted) setState(() => categories = fetchedCategories);
    } catch (e) {
      _showSnackBar('Error loading categories: $e', isError: true);
    }
  }

  void _showAddExpenseDialog() {
    TextEditingController amountController = TextEditingController();
    TextEditingController notesController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    String? selectedCategoryId;

    Future<void> _pickDate() async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate!,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        ),
      );
      if (pickedDate != null && mounted) {
        setState(() => selectedDate = pickedDate);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          title: Text(
            'Add Expense',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                    prefixIcon: const Icon(Icons.attach_money,
                        color: Colors.blueAccent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'Select Expense Date'
                                : DateFormat('yyyy-MM-dd')
                                    .format(selectedDate!),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: selectedDate == null
                                  ? Colors.grey[700]
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  items: categories
                      .map((category) => DropdownMenuItem<String>(
                            value: category["id"] as String,
                            child: Text(category["name"],
                                style: GoogleFonts.poppins()),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedCategoryId = value),
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                    prefixIcon:
                        const Icon(Icons.category, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                    prefixIcon:
                        const Icon(Icons.note, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty ||
                    selectedDate == null ||
                    selectedCategoryId == null) {
                  _showSnackBar('Please fill in all required fields.',
                      isError: true);
                  return;
                }

                double? amount = double.tryParse(amountController.text);
                if (amount == null) {
                  _showSnackBar('Invalid amount entered.', isError: true);
                  return;
                }

                try {
                  await ExpenseService.addExpense(
                    amount: amount,
                    categoryId: selectedCategoryId!,
                    date: selectedDate!,
                    notes: notesController.text.trim(),
                  );
                  _showSnackBar('Expense added successfully!', isSuccess: true);
                  _loadExpenses();
                  Navigator.pop(context);
                } catch (e) {
                  _showSnackBar('Error adding expense: $e', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Add Expense',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(String expenseId) async {
    try {
      bool success = await ExpenseService.deleteExpense(expenseId);
      if (success) {
        _showSnackBar('Expense deleted successfully!', isSuccess: true);
        _loadExpenses();
      } else {
        _showSnackBar('Failed to delete expense.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error deleting expense: $e', isError: true);
    }
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor:
            isSuccess ? Colors.green : (isError ? Colors.red : null),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Expense Tracking',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _loadExpenses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : expenses.isEmpty
              ? Center(
                  child: Text(
                    'No expenses found.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 12),
                    _buildExpensesList(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Overview',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track and manage your expenses',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expenses',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                var expense = expenses[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.monetization_on,
                        color: Colors.blueAccent, size: 24),
                    title: Text(
                      '\$${expense["amount"].toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(expense["date"]))}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        Text(
                          'Category: ${expense["category"]}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        if (expense["notes"] != null &&
                            expense["notes"].isNotEmpty)
                          Text(
                            'Notes: ${expense["notes"]}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.delete, color: Colors.red, size: 20),
                      tooltip: 'Delete Expense',
                      onPressed: () => _deleteExpense(expense["id"]),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
