import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:teamstream/services/pocketbase/my_account_service.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/utils/constants.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  late final MyAccountService myAccountService;
  Map<String, dynamic> userProfile = {};
  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    final pb = Provider.of<PocketBase>(context, listen: false);
    myAccountService = MyAccountService(pb);
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => isLoading = true);
    try {
      final profile = await myAccountService.fetchUserProfile();
      setState(() {
        userProfile = profile;
      });
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error loading profile. Please try again.')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _uploadProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() => isUploading = true);
      final filePath = result.files.single.path;
      if (filePath != null) {
        try {
          await myAccountService.updateProfilePicture(filePath);
          print('✅ Profile picture updated successfully');
          _fetchUserProfile();
        } catch (e) {
          print('❌ Error uploading profile picture: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile picture.')),
          );
        } finally {
          setState(() => isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUserProfile,
            tooltip: 'Refresh Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService.clearLoggedInUser();
              Navigator.pushReplacementNamed(context, '/');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildUserInfoSection(isDarkMode),
                  const SizedBox(height: 20),
                  _buildActionsSection(),
                  const SizedBox(height: 20),
                  _buildProfileSection(),
                  const SizedBox(height: 20),
                  _buildAddressSection(),
                  const SizedBox(height: 20),
                  _buildEmergencyContactSection(),
                  const SizedBox(height: 20),
                  _buildCertificationsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoSection(bool isDarkMode) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _uploadProfilePicture,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: userProfile['avatar'] != null
                        ? CachedNetworkImageProvider(
                            "$pocketBaseUrl/api/files/users/${userProfile['id']}/${userProfile['avatar']}",
                          )
                        : null,
                    child: userProfile['avatar'] == null
                        ? const Icon(Icons.person,
                            size: 40, color: Colors.white)
                        : null,
                  ),
                  if (isUploading)
                    const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              userProfile['name'] ?? 'No name provided',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${userProfile['role'] ?? 'No role assigned'}',
              style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              userProfile['phone'] ?? 'No phone provided',
              style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              userProfile['email'] ?? 'No email provided',
              style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _buildActionTile(
              Icons.camera_alt, 'Change My Picture', _uploadProfilePicture),
          _buildActionTile(Icons.lock, 'Change My Password', () {}),
          _buildActionTile(Icons.assignment, 'Permits', () {}),
          _buildActionTile(Icons.warning, 'Warnings', () {}),
          _buildActionTile(Icons.approval, 'Approvals', () {}),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
            leading: Icon(icon, color: Colors.blueAccent),
            title: Text(title),
            onTap: onTap),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildProfileSection() {
    return _buildInfoCard("Profile", {
      "Start Date": userProfile['start_date'] ?? 'Not provided',
      "Branch": userProfile['branch'] is String
          ? userProfile['branch']
          : (userProfile['branch']?['name'] ??
              'Not provided'), // Handle relation
      "Position": userProfile['position'] ?? 'Not provided',
      "Area": userProfile['area'] ?? 'Not provided',
    });
  }

  Widget _buildAddressSection() {
    return _buildInfoCard("Address", {
      "Street": userProfile['street'] ?? 'Not provided',
      "City": userProfile['city'] ?? 'Not provided',
      "State": userProfile['state'] ?? 'Not provided',
      "Zip Code": userProfile['zip_code'] ?? 'Not provided',
    });
  }

  Widget _buildEmergencyContactSection() {
    return _buildInfoCard("Emergency Contact", {
      "Name": userProfile['emergency_contact_name'] ?? 'Not provided',
      "Phone": userProfile['emergency_contact_phone'] ?? 'Not provided',
    });
  }

  Widget _buildCertificationsSection() {
    return _buildInfoCard("Certifications", {
      "Food Cert Expiry": userProfile['food_cert_expiry'] ?? 'Not provided',
      "Alcohol Cert Expiry":
          userProfile['alcohol_cert_expiry'] ?? 'Not provided',
      "Certifications": userProfile['certifications'] ?? 'Not provided',
    });
  }

  Widget _buildInfoCard(String title, Map<String, String> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...data.entries.map((e) => _buildInfoRow(e.key, e.value)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
