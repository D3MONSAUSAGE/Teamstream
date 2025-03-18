import 'package:flutter/material.dart';
import 'package:teamstream/models/product.dart';
import 'package:teamstream/services/pocketbase/inventory_service.dart';

class InventoryReportPage extends StatefulWidget {
  const InventoryReportPage({super.key});

  @override
  _InventoryReportPageState createState() => _InventoryReportPageState();
}

class _InventoryReportPageState extends State<InventoryReportPage> {
  List<Product> inventoryData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    try {
      final data = await InventoryService.fetchInventory();
      setState(() {
        inventoryData = data;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching inventory data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Report")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inventoryData.length,
              itemBuilder: (context, index) {
                var item = inventoryData[index];
                return Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text("Stock: ${item.quantity}"),
                  ),
                );
              },
            ),
    );
  }
}
