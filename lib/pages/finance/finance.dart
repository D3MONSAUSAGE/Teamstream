import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/pages/finance/invoice_list.dart';
import 'package:teamstream/pages/finance/invoice_upload.dart';
import 'package:teamstream/pages/finance/expense_tracking.dart';
import 'package:teamstream/pages/finance/sales_reports.dart';
import 'package:teamstream/pages/finance/miles_page.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  FinancePageState createState() => FinancePageState();
}

class FinancePageState extends State<FinancePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Finance Overview',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      drawer: const MenuDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 12),
          _buildSection('Manage Finances', [
            _buildFinanceOption(
              context,
              title: 'View Invoices',
              icon: Icons.receipt_long,
              page: const InvoiceListPage(),
            ),
            _buildFinanceOption(
              context,
              title: 'Upload Invoice',
              icon: Icons.upload_file,
              page: const InvoiceUploadPage(),
            ),
            _buildFinanceOption(
              context,
              title: 'Expense Tracking',
              icon: Icons.money_off,
              page: const ExpenseTrackingPage(),
            ),
            _buildFinanceOption(
              context,
              title: 'Daily Sales Reports',
              icon: Icons.show_chart,
              page: const SalesReportsPage(),
            ),
            _buildFinanceOption(
              context,
              title: 'Mileage Tracking',
              icon: Icons.directions_car,
              page: const MilesPage(),
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection('Upcoming Features', [
            _buildFinanceOption(
              context,
              title: 'Budget Planning (Coming Soon)',
              icon: Icons.account_balance_wallet,
              page: const PlaceholderPage(title: 'Budget Planning'),
            ),
            _buildFinanceOption(
              context,
              title: 'Tax Calculations (Coming Soon)',
              icon: Icons.calculate,
              page: const PlaceholderPage(title: 'Tax Calculations'),
            ),
          ]),
        ],
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
              'Finance Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track and manage your financial activities',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.blue[900],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.46,
              child: option,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFinanceOption(BuildContext context,
      {required String title, required IconData icon, required Widget page}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => page));
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          '🚀 Feature Coming Soon! Stay Tuned!',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.blue[900],
          ),
        ),
      ),
    );
  }
}
