import 'package:flutter/material.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Financial Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSummaryCard("Total Revenue", "\$50,000"),
            _buildSummaryCard("Total Expenses", "\$30,000"),
            _buildSummaryCard("Net Profit", "\$20,000"),
            const SizedBox(height: 20),
            const Text(
              "Recent Transactions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildTransactionTile(
                      "Vendor Payment", "-\$2,000", "02/15/2024"),
                  _buildTransactionTile(
                      "Sales Revenue", "+\$5,000", "02/14/2024"),
                  _buildTransactionTile(
                      "Inventory Purchase", "-\$1,500", "02/13/2024"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(amount, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildTransactionTile(String title, String amount, String date) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(title),
        subtitle: Text(date),
        trailing: Text(amount,
            style: TextStyle(
                color: amount.contains("-") ? Colors.red : Colors.green)),
      ),
    );
  }
}
