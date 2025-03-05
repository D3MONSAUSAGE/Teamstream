import 'package:flutter/material.dart';
import '/widgets/menu_drawer.dart'; // Import your MenuDrawer

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Use the current theme

    // Dummy data for inventory items
    final List<Map<String, String>> inventoryItems = [
      {
        "name": "Laptop",
        "quantity": "10",
        "location": "Warehouse A",
        "status": "In Stock",
      },
      {
        "name": "Monitor",
        "quantity": "25",
        "location": "Warehouse B",
        "status": "In Stock",
      },
      {
        "name": "Keyboard",
        "quantity": "50",
        "location": "Warehouse C",
        "status": "Low Stock",
      },
      {
        "name": "Mouse",
        "quantity": "75",
        "location": "Warehouse A",
        "status": "In Stock",
      },
      {
        "name": "Printer",
        "quantity": "5",
        "location": "Warehouse B",
        "status": "Out of Stock",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Inventory",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ), // Use theme text style
        ),
      ),
      drawer: const MenuDrawer(), // Add the MenuDrawer
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Inventory Overview",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Manage and track your inventory items.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),

            // Inventory List
            ListView.separated(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling
              itemCount: inventoryItems.length,
              separatorBuilder: (context, index) => Divider(
                color: theme.dividerColor.withOpacity(0.1), // Subtle divider
              ),
              itemBuilder: (context, index) {
                final item = inventoryItems[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                      Icons.inventory,
                      size: 40,
                      color: theme.primaryColor, // Use theme primary color
                    ),
                    title: Text(
                      item["name"]!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Quantity: ${item["quantity"]}",
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          "Location: ${item["location"]}",
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          "Status: ${item["status"]}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: item["status"] == "Out of Stock"
                                ? Colors.red
                                : item["status"] == "Low Stock"
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ],
                    ),
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
