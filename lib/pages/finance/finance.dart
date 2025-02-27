import 'package:flutter/material.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/pages/finance/invoice_list.dart';
import 'package:teamstream/pages/finance/invoice_upload.dart';
import 'package:teamstream/pages/finance/expense_tracking.dart';
import 'package:teamstream/pages/finance/sales_reports.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  FinancePageState createState() => FinancePageState();
}

class FinancePageState extends State<FinancePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finance Overview")),
      drawer: const MenuDrawer(), // ✅ Ensures the menu drawer is included
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Finances",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 🔹 View & Upload Invoices
            _buildFinanceOption(
              context,
              title: "View Invoices",
              icon: Icons.receipt_long,
              page: const InvoiceListPage(),
            ),
            _buildFinanceOption(
              context,
              title: "Upload Invoice",
              icon: Icons.upload_file,
              page: const InvoiceUploadPage(),
            ),

            // 🔹 Expense Tracking
            _buildFinanceOption(
              context,
              title: "Expense Tracking",
              icon: Icons.money_off,
              page: const ExpenseTrackingPage(),
            ),

            // 🔹 Sales Reports (Daily Sales)
            _buildFinanceOption(
              context,
              title: "Daily Sales Reports",
              icon: Icons.show_chart,
              page: const SalesReportsPage(),
            ),

            const SizedBox(height: 20),

            const Text(
              "Upcoming Features",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _buildFinanceOption(
              context,
              title: "Budget Planning (Coming Soon)",
              icon: Icons.account_balance_wallet,
              page: const PlaceholderPage(title: "Budget Planning"),
            ),

            _buildFinanceOption(
              context,
              title: "Tax Calculations (Coming Soon)",
              icon: Icons.calculate,
              page: const PlaceholderPage(title: "Tax Calculations"),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Builds a finance option card
  Widget _buildFinanceOption(BuildContext context,
      {required String title, required IconData icon, required Widget page}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => page));
        },
      ),
    );
  }
}

/// 🔹 Placeholder Page for Future Features
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text("🚀 Feature Coming Soon! Stay Tuned!")),
    );
  }
}
