import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  TrainingPageState createState() => TrainingPageState();
}

class TrainingPageState extends State<TrainingPage> {
  final List<Map<String, dynamic>> trainingModules = [
    {"title": "Food Safety Training", "completed": true},
    {"title": "Customer Service Excellence", "completed": false},
    {"title": "Inventory Management", "completed": false},
    {"title": "Workplace Safety", "completed": true},
  ];

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor:
            isSuccess ? Colors.green : (isError ? Colors.red : null),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Employee Training',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.notifications, color: Colors.white, size: 28),
            onPressed: () {
              _showSnackBar('Notifications clicked - functionality TBD');
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: const MenuDrawer(), // Added MenuDrawer
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training Overview',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your progress.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            _buildProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Training Modules',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: trainingModules.length,
                itemBuilder: (context, index) {
                  final module = trainingModules[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(
                        module["title"],
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      trailing: module["completed"]
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.circle_outlined,
                              color: Colors.grey),
                      onTap: () {
                        _showSnackBar('Module details coming soon!');
                        // Future functionality to open module details
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    int completedCount =
        trainingModules.where((module) => module["completed"]).length;
    double progress = completedCount / trainingModules.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training Progress',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
            const SizedBox(height: 8),
            Text(
              "${(progress * 100).toInt()}% Completed",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
