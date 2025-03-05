import 'package:flutter/material.dart';
import 'package:teamstream/widgets/menu_drawer.dart'; // Import the MenuDrawer

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Dashboard"),
      ),
      drawer: const MenuDrawer(), // Add the MenuDrawer here
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            const Text(
              "Quick Stats",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStatCard("Total Mileage", "\$1,200"),
                const SizedBox(width: 10),
                _buildStatCard("Pending Requests", "5"),
                const SizedBox(width: 10),
                _buildStatCard("Compliance Rate", "95%"),
              ],
            ),
            const SizedBox(height: 20),

            // Reports
            const Text(
              "Reports",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildReportCard("Mileage Reports", Icons.directions_car),
                _buildReportCard("Employee Requests", Icons.request_page),
                _buildReportCard("Payroll Overview", Icons.attach_money),
                _buildReportCard("Training Tracking", Icons.school),
              ],
            ),
            const SizedBox(height: 20),

            // Notifications
            const Text(
              "Notifications",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text("Notification ${index + 1}"),
                  subtitle: const Text("This is a sample notification."),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, IconData icon) {
    return Card(
      child: InkWell(
        onTap: () {
          // Navigate to the corresponding report page
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 10),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
