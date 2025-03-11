import 'package:flutter/material.dart';
import 'package:teamstream/pages/login.dart';
import 'package:teamstream/pages/dashboard.dart';
import 'package:teamstream/pages/my_account_page.dart';
import 'package:teamstream/pages/finance/finance.dart';
import 'package:teamstream/pages/human_resources.dart';
import 'package:teamstream/pages/training.dart';
import 'package:teamstream/pages/requests_page.dart';
import 'package:teamstream/pages/documents/documents.dart';
import 'package:teamstream/pages/checklists/checklists.dart'; // Updated import
import 'package:teamstream/pages/manager_dashboard.dart'; // Import the ManagerDashboard page
import 'package:teamstream/utils/theme.dart'; // Import the theme file
import 'package:teamstream/pages/inventory/inventory.dart'; // Import the Inventory page

void main() {
  WidgetsFlutterBinding
      .ensureInitialized(); // ✅ Ensures plugins are initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CustomTheme.getLightTheme, // Access the getter (no parentheses)
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/my_account': (context) => const MyAccountPage(),
        '/finance': (context) => const FinancePage(),
        '/human_resources': (context) => const HumanResourcesPage(),
        '/training': (context) => const TrainingPage(),
        '/requests': (context) => const RequestsPage(),
        '/checklists': (context) => const ChecklistsPage(), // Updated route
        '/documents': (context) => const DocumentsPage(),
        '/inventory': (context) =>
            const InventoryPage(), // Ensure this matches the class name
        '/manager_dashboard': (context) =>
            const ManagerDashboard(), // Add this line
      },
    );
  }
}
