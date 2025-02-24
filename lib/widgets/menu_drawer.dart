import 'package:flutter/material.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
                ),
                const SizedBox(height: 10),
                Text(
                  "Welcome, User!",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  "user@email.com",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          _buildMenuItem(context, Icons.dashboard, "Dashboard", '/dashboard'),
          _buildMenuItem(context, Icons.person, "My Account", '/my_account'),
          _buildMenuItem(context, Icons.schedule, "Schedules", '/schedules'),
          _buildMenuItem(context, Icons.attach_money, "Finance", '/finance'),
          _buildMenuItem(
              context, Icons.business, "Human Resources", '/human_resources'),
          _buildMenuItem(context, Icons.school, "Training", '/training'),
          _buildMenuItem(context, Icons.request_page, "Requests", '/requests'),
          _buildMenuItem(context, Icons.checklist, "Checklists", '/checklists'),
          _buildMenuItem(context, Icons.file_copy, "Documents", '/documents'),

          const Divider(), // Adds a separator line

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}
