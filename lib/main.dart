import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:teamstream/pages/login.dart';
import 'package:teamstream/pages/dashboard.dart';
import 'package:teamstream/pages/my_account_page.dart';
import 'package:teamstream/pages/finance/finance.dart';
import 'package:teamstream/pages/human_resources.dart';
import 'package:teamstream/pages/training.dart';
import 'package:teamstream/pages/requests_page.dart';
import 'package:teamstream/pages/documents/documents.dart';
import 'package:teamstream/pages/checklists/checklists_page.dart';
import 'package:teamstream/pages/manager_dashboard/manager_dashboard.dart';
import 'package:teamstream/pages/manage_time/timecard_page.dart';
import 'package:teamstream/pages/inventory/inventory.dart';
import 'package:teamstream/pages/schedules/schedules_page.dart';
import 'package:teamstream/pages/warnings_page.dart'; // Added import for WarningsPage
import 'package:teamstream/utils/theme.dart';
import 'package:teamstream/utils/constants.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final pb = PocketBase(pocketBaseUrl);
    AuthService.init(pb);

    return MultiProvider(
      providers: [
        Provider<PocketBase>(create: (_) => pb),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: CustomTheme.getLightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginPage(),
          '/dashboard': (context) => const DashboardPage(),
          '/my_account': (context) => const MyAccountPage(),
          '/finance': (context) => const FinancePage(),
          '/human_resources': (context) => const HumanResourcesPage(),
          '/training': (context) => const TrainingPage(),
          '/requests': (context) => const RequestsPage(),
          '/checklists': (context) => const ChecklistsPage(),
          '/documents': (context) => const DocumentsPage(),
          '/inventory': (context) => const InventoryPage(),
          '/manager_dashboard': (context) => const ManagerDashboardPage(),
          '/schedules': (context) => const SchedulesPage(),
          '/timecard': (context) => const TimecardPage(),
          '/warnings': (context) =>
              const WarningsPage(), // Added route for WarningsPage
        },
      ),
    );
  }
}
