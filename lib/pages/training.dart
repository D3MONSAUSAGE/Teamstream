import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Employee Training")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Training Progress",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildProgressIndicator(),
            const SizedBox(height: 20),
            const Text("Training Modules",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: trainingModules.length,
                itemBuilder: (context, index) {
                  final module = trainingModules[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(module["title"]),
                      trailing: module["completed"]
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.circle_outlined,
                              color: Colors.grey),
                      onTap: () {
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

    return Column(
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 5),
        Text(
          "${(progress * 100).toInt()}% Completed",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
