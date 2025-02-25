import 'package:flutter/material.dart';
import 'package:teamstream/pages/login.dart';
import 'package:teamstream/pages/dashboard.dart';
import 'package:teamstream/pages/my_account.dart';
import 'package:teamstream/pages/finance.dart';
import 'package:teamstream/pages/human_resources.dart';
import 'package:teamstream/pages/training.dart';
import 'package:teamstream/pages/requests_page.dart';
import 'package:teamstream/pages/documents.dart';
import 'package:teamstream/pages/checklists.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/my_account': (context) => const MyAccountPage(),
        //'/schedules': (context) => const SchedulesPage(),
        '/finance': (context) => const FinancePage(),
        '/human_resources': (context) => const HumanResourcesPage(),
        '/training': (context) => const TrainingPage(),
        '/requests': (context) => const RequestsPage(),
        '/checklists': (context) => const ChecklistsPage(),
        '/documents': (context) => const DocumentsPage(),
      },
    );
  }
}
