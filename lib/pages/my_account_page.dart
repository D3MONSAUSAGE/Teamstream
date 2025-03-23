import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
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
        SnackBar(
          content: Text(
            'Error loading profile. Please try again.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
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
            SnackBar(
              content: Text(
                'Failed to update profile picture.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } finally {
          setState(() => isUploading = false);
        }
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? errorMessage;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'Change Password',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    TextField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.grey[700],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.grey[700],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.grey[700],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() {
                            errorMessage = null;
                            isLoading = true;
                          });

                          final currentPassword =
                              currentPasswordController.text.trim();
                          final newPassword = newPasswordController.text.trim();
                          final confirmPassword =
                              confirmPasswordController.text.trim();

                          // Validation
                          if (currentPassword.isEmpty ||
                              newPassword.isEmpty ||
                              confirmPassword.isEmpty) {
                            setDialogState(() {
                              errorMessage = 'All fields are required.';
                              isLoading = false;
                            });
                            return;
                          }

                          if (newPassword != confirmPassword) {
                            setDialogState(() {
                              errorMessage = 'New passwords do not match.';
                              isLoading = false;
                            });
                            return;
                          }

                          if (newPassword.length < 8) {
                            setDialogState(() {
                              errorMessage =
                                  'New password must be at least 8 characters long.';
                              isLoading = false;
                            });
                            return;
                          }

                          try {
                            await AuthService.changePassword(
                              currentPassword: currentPassword,
                              newPassword: newPassword,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Password changed successfully!',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            // Log out the user after password change
                            AuthService.clearLoggedInUser();
                            Navigator.pushReplacementNamed(context, '/');
                          } catch (e) {
                            setDialogState(() {
                              errorMessage = e.toString();
                              isLoading = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Change Password',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'My Account',
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
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _fetchUserProfile,
            tooltip: 'Refresh Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
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
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your account details.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildUserInfoSection(isDarkMode),
                    ),
                  ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _uploadProfilePicture,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: userProfile['avatar'] != null
                          ? CachedNetworkImageProvider(
                              "$pocketBaseUrl/api/files/users/${userProfile['id']}/${userProfile['avatar']}",
                            )
                          : null,
                      child: userProfile['avatar'] == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.blueAccent,
                            )
                          : null,
                    ),
                  ),
                  if (isUploading)
                    const CircularProgressIndicator(
                      color: Colors.blueAccent,
                      strokeWidth: 3,
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userProfile['name'] ?? 'No name provided',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${userProfile['role'] ?? 'No role assigned'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userProfile['phone'] ?? 'No phone provided',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userProfile['email'] ?? 'No email provided',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildActionTile(
            Icons.camera_alt,
            'Change My Picture',
            _uploadProfilePicture,
            Colors.blueAccent,
          ),
          _buildActionTile(
            Icons.lock,
            'Change My Password',
            _changePassword,
            Colors.blueAccent,
          ),
          _buildActionTile(
            Icons.assignment,
            'Requests',
            () => Navigator.pushNamed(context, '/requests'),
            Colors.blueAccent,
          ),
          _buildActionTile(
            Icons.warning,
            'Warnings',
            () => Navigator.pushNamed(context, '/warnings'),
            Colors.orange,
          ),
          // Removed Approvals action tile
        ],
      ),
    );
  }

  Widget _buildActionTile(
      IconData icon, String title, VoidCallback onTap, Color iconColor) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor, size: 28),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blue[900],
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
            size: 16,
          ),
          onTap: onTap,
        ),
        const Divider(height: 1, color: Colors.grey),
      ],
    );
  }

  Widget _buildProfileSection() {
    return _buildInfoCard("Profile", {
      "Start Date": userProfile['start_date'] ?? 'Not provided',
      "Branch": userProfile['branch'] is String
          ? userProfile['branch']
          : (userProfile['branch']?['name'] ?? 'Not provided'),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            ...data.entries.map((e) => _buildInfoRow(e.key, e.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
