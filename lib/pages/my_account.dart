import 'package:flutter/material.dart';
import 'package:teamstream/services/pocketbase_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  MyAccountPageState createState() => MyAccountPageState();
}

class MyAccountPageState extends State<MyAccountPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    try {
      final fetchedUserData = await PocketBaseService.getLoggedInUserId();
      setState(() {
        userData = fetchedUserData as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Account")),
      drawer: const MenuDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text("⚠️ Failed to load user data."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Personal Information"),
                      _buildInfoTile("Role", userData?['role']),
                      _buildInfoTile("Branch", userData?['branch']),
                      _buildInfoTile("Phone Number", userData?['phone']),
                      _buildInfoTile("Email", userData?['email']),
                      _buildInfoTile("Address", userData?['address']),
                      _buildInfoTile(
                          "Employment Start Date", userData?['start_date']),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Additional Details"),
                      _buildInfoTile(
                          "Warnings", userData?['warnings'] ?? "None"),
                      _buildCertificationsList(),
                      _buildRequestsList(),
                      _buildEmergencyContact(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: userData?['profile_picture'] != null
                  ? NetworkImage(userData?['profile_picture'])
                  : const AssetImage('assets/default_profile.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userData?['name'] ?? "Unknown",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(userData?['role'] ?? "Role not assigned",
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoTile(String title, String? value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value ?? "Not available"),
      leading: const Icon(Icons.info, color: Colors.blue),
    );
  }

  Widget _buildCertificationsList() {
    List<dynamic>? certifications = userData?['certifications'];

    if (certifications == null || certifications.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          title: const Text("Certifications",
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("No certifications available"),
          leading: const Icon(Icons.badge, color: Colors.green),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: const Text("Certifications",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: certifications
              .map((cert) => cert is String
                  ? Text("• $cert")
                  : const Text("• Invalid Data"))
              .toList(),
        ),
        leading: const Icon(Icons.badge, color: Colors.green),
      ),
    );
  }

  Widget _buildRequestsList() {
    List<dynamic> requests = userData?['requests'] ?? [];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: const Text("Submitted Requests",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: requests.isEmpty
            ? const Text("No requests submitted")
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: requests.map((req) => Text("• $req")).toList(),
              ),
        leading: const Icon(Icons.pending_actions, color: Colors.orange),
      ),
    );
  }

  Widget _buildEmergencyContact() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: const Text("Emergency Contact",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Name: ${userData?['emergency_contact_name'] ?? 'Not available'}"),
            Text(
                "Phone: ${userData?['emergency_contact_phone'] ?? 'Not available'}"),
          ],
        ),
        leading: const Icon(Icons.emergency, color: Colors.red),
      ),
    );
  }
}
