import 'package:flutter/material.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  TrainingPageState createState() => TrainingPageState();
}

class TrainingPageState extends State<TrainingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text("Training"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Training Progress"),
            Tab(text: "Quizzes"),
            Tab(text: "Materials"),
          ],
        ),
      ),
      drawer: const MenuDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          TrainingProgressTab(),
          QuizzesTab(),
          TrainingMaterialsTab(),
        ],
      ),
    );
  }
}

// --------------------------------------
// 🔹 TRAINING PROGRESS TAB
// --------------------------------------
class TrainingProgressTab extends StatelessWidget {
  final double trainingCompletion = 0.65; // Example: 65% complete

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "90-Day Training Progress",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 20,
              width: double.infinity,
              color: Colors.grey[300],
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: trainingCompletion,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text("${(trainingCompletion * 100).toInt()}% Completed",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text(
            "Next Steps:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text("Complete Onboarding Documentation"),
          ),
          const ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text("Watch Safety Training Videos"),
          ),
          const ListTile(
            leading: Icon(Icons.radio_button_unchecked, color: Colors.grey),
            title: Text("Pass the Restaurant Policy Quiz"),
          ),
          const ListTile(
            leading: Icon(Icons.radio_button_unchecked, color: Colors.grey),
            title: Text("Complete First Evaluation Meeting"),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------
// 🔹 QUIZZES TAB
// --------------------------------------
class QuizzesTab extends StatelessWidget {
  final List<Map<String, String>> quizzes = [
    {"title": "Food Safety", "status": "Completed"},
    {"title": "Customer Service", "status": "In Progress"},
    {"title": "Kitchen Procedures", "status": "Not Started"},
    {"title": "POS System Training", "status": "Not Started"},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Available Quizzes",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(quiz['title']!),
                    subtitle: Text("Status: ${quiz['status']}"),
                    trailing: Icon(
                      quiz['status'] == "Completed"
                          ? Icons.check_circle
                          : quiz['status'] == "In Progress"
                              ? Icons.hourglass_bottom
                              : Icons.radio_button_unchecked,
                      color: quiz['status'] == "Completed"
                          ? Colors.green
                          : quiz['status'] == "In Progress"
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("${quiz['title']} coming soon!")),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------
// 🔹 TRAINING MATERIALS TAB
// --------------------------------------
class TrainingMaterialsTab extends StatelessWidget {
  final List<Map<String, String>> materials = [
    {"title": "Employee Handbook", "link": "#"},
    {"title": "Kitchen Safety Guide", "link": "#"},
    {"title": "Customer Service Excellence", "link": "#"},
    {"title": "POS System User Guide", "link": "#"},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Training Materials",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: materials.length,
              itemBuilder: (context, index) {
                final material = materials[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(material['title']!),
                    trailing: const Icon(Icons.open_in_new, color: Colors.blue),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "Opening ${material['title']} (Feature coming soon)")),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
