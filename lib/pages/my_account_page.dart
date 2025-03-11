import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teamstream/services/pocketbase/my_account_service.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  final PocketBase pb =
      PocketBase('http://localhost:8090'); // Replace with your PocketBase URL
  late final MyAccountService myAccountService;
  Map<String, dynamic> userProfile = {};

  @override
  void initState() {
    super.initState();
    myAccountService = MyAccountService(pb);
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await myAccountService.fetchUserProfile();
      setState(() {
        userProfile = profile;
      });
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _uploadProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      final filePath = result.files.single.path;
      if (filePath != null) {
        try {
          await myAccountService.updateProfilePicture(filePath);
          print('Profile picture updated successfully');
          _fetchUserProfile(); // Refresh the profile data
        } catch (e) {
          print('Error uploading profile picture: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoSection(),
            const SizedBox(height: 20),
            _buildActionsSection(),
            const SizedBox(height: 20),
            _buildProfileSection(),
            const SizedBox(height: 20),
            _buildAddressSection(),
            const SizedBox(height: 20),
            _buildCertificationsSection(),
            const SizedBox(height: 20),
            _buildEmergencyContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _uploadProfilePicture,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blueAccent,
                backgroundImage: userProfile['profile_picture'] != null
                    ? NetworkImage(pb
                        .getFileUrl(RecordModel.fromJson(userProfile),
                            userProfile['profile_picture'].toString())
                        .toString())
                    : null,
                child: userProfile['profile_picture'] == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              userProfile['email'] ?? 'No email provided',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Roles: ${(userProfile['roles'] as List?)?.join(', ') ?? 'No roles'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              userProfile['phone'] ?? 'No phone provided',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
            title: const Text('Change My Picture'),
            onTap: _uploadProfilePicture,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.blueAccent),
            title: const Text('Change My Password'),
            onTap: () {
              // Add functionality to change password
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.assignment, color: Colors.blueAccent),
            title: const Text('Permits'),
            onTap: () {
              // Add functionality for permits
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.blueAccent),
            title: const Text('Warnings'),
            onTap: () {
              // Add functionality for warnings
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.approval, color: Colors.blueAccent),
            title: const Text('Approvals'),
            onTap: () {
              // Add functionality for approvals
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildInfoRow('Employee since',
                userProfile['employee_since'] ?? 'Not provided'),
            _buildInfoRow('Branch', userProfile['branch'] ?? 'Not provided'),
            _buildInfoRow('Area', userProfile['area'] ?? 'Not provided'),
            _buildInfoRow(
                'Position', userProfile['position'] ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildInfoRow('Street', userProfile['street'] ?? 'Not provided'),
            _buildInfoRow('City', userProfile['city'] ?? 'Not provided'),
            _buildInfoRow('State', userProfile['state'] ?? 'Not provided'),
            _buildInfoRow(
                'ZIP Code', userProfile['zip_code'] ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Certifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildInfoRow('Food certification expiration date',
                userProfile['food_cert_expiry'] ?? 'Not provided'),
            _buildInfoRow('Alcohol certification expiration date',
                userProfile['alcohol_cert_expiry'] ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildInfoRow('Name',
                userProfile['emergency_contact_name'] ?? 'Not provided'),
            _buildInfoRow('Phone',
                userProfile['emergency_contact_phone'] ?? 'Not provided'),
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
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
