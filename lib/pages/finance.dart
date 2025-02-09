import 'package:flutter/material.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/services/pocketbase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  FinancePageState createState() => FinancePageState();
}

class FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Finance Management"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color.fromARGB(255, 29, 187, 29),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Fixed Costs"),
            Tab(text: "Daily Sales"),
            Tab(text: "Invoices"),
            Tab(text: "Vendors"),
          ],
        ),
      ),
      drawer: const MenuDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          FixedCostsTab(),
          DailySalesTab(),
          InvoicesTab(),
          VendorsTab(),
        ],
      ),
    );
  }
}

class FixedCostsTab extends StatefulWidget {
  @override
  _FixedCostsTabState createState() => _FixedCostsTabState();
}

class _FixedCostsTabState extends State<FixedCostsTab> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedVendor = "";
  List<String> vendors = ["Vendor A", "Vendor B", "Vendor C"];
  List<Map<String, dynamic>> costsHistory = [];

  void addFixedCost() {
    setState(() {
      costsHistory.add({
        "amount": amountController.text,
        "frequency": frequencyController.text,
        "vendor": selectedVendor,
        "description": descriptionController.text,
        "date": DateTime.now().toIso8601String(),
      });
      amountController.clear();
      frequencyController.clear();
      descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add Fixed Cost",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: "Amount"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: frequencyController,
                    decoration: const InputDecoration(
                        labelText: "Frequency (e.g. Monthly, Weekly)"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField(
                    value: selectedVendor.isEmpty ? null : selectedVendor,
                    hint: const Text("Select Vendor"),
                    items: vendors.map((vendor) {
                      return DropdownMenuItem(
                          value: vendor, child: Text(vendor));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedVendor = value.toString();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: addFixedCost,
                    child: const Text("Add Fixed Cost"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DailySalesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Daily Sales Trend",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(1, 5000),
                      const FlSpot(2, 7000),
                      const FlSpot(3, 9000),
                      const FlSpot(4, 11000),
                    ],
                    isCurved: true,
                    barWidth: 4,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InvoicesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Invoices Management (Upload, Search, View)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}

class VendorsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Vendors Management (Add, Remove, View)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}
