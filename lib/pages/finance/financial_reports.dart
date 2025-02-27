import 'package:flutter/material.dart';

class FinancialReportsPage extends StatelessWidget {
  const FinancialReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Financial Reports")),
      body: const Center(
        child: Text("Profit & Loss Reports Coming Soon!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
