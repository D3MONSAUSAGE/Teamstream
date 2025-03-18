import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/services/pocketbase_service.dart';

class HumanResourcesPage extends StatefulWidget {
  const HumanResourcesPage({super.key});

  @override
  HumanResourcesPageState createState() => HumanResourcesPageState();
}

class HumanResourcesPageState extends State<HumanResourcesPage> {
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
          'Human Resources',
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
            onPressed: () =>
                _showSnackBar('Notifications clicked - functionality TBD'),
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'HR Overview',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your team efficiently.',
                style:
                    GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),

              // Employees Section
              _buildSection(
                title: 'Employees',
                icon: Icons.people,
                content: EmployeesSection(showSnackBar: _showSnackBar),
              ),
              const SizedBox(height: 20),

              // Onboarding Section
              _buildSection(
                title: 'Onboarding',
                icon: Icons.person_add,
                content: OnboardingSection(showSnackBar: _showSnackBar),
              ),
              const SizedBox(height: 20),

              // Quick Actions Section
              _buildSection(
                title: 'Quick Actions',
                icon: Icons.dashboard,
                content: QuickActionsSection(showSnackBar: _showSnackBar),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title,
      required IconData icon,
      required Widget content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }
}

// Employees Section
class EmployeesSection extends StatefulWidget {
  final void Function(String, {bool isSuccess, bool isError}) showSnackBar;

  const EmployeesSection({super.key, required this.showSnackBar});

  @override
  EmployeesSectionState createState() => EmployeesSectionState();
}

class EmployeesSectionState extends State<EmployeesSection> {
  List<Map<String, dynamic>> employees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    setState(() => isLoading = true);
    try {
      List<Map<String, dynamic>> fetchedEmployees =
          await PocketBaseService.fetchEmployees();
      setState(() {
        employees = fetchedEmployees;
        isLoading = false;
      });
    } catch (e) {
      widget.showSnackBar('Error fetching employees: $e', isError: true);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Members (${employees.length})',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
        ),
        const SizedBox(height: 12),
        isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent))
            : employees.isEmpty
                ? Text(
                    'No employees found.',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[600]),
                  )
                : SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: GestureDetector(
                            onTap: () => widget
                                .showSnackBar('Employee profile coming soon!'),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blueAccent,
                                  child: Text(
                                    employee['name']
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        'N/A',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white, fontSize: 24),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  employee['name'] ?? 'Unknown',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  employee['role'] ?? 'No Role',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: fetchEmployees,
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            label: Text('Refresh',
                style: GoogleFonts.poppins(color: Colors.blueAccent)),
          ),
        ),
      ],
    );
  }
}

// Onboarding Section
class OnboardingSection extends StatefulWidget {
  final void Function(String, {bool isSuccess, bool isError}) showSnackBar;

  const OnboardingSection({super.key, required this.showSnackBar});

  @override
  _OnboardingSectionState createState() => _OnboardingSectionState();
}

class _OnboardingSectionState extends State<OnboardingSection> {
  final TextEditingController nameController = TextEditingController();
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add New Employee',
                style:
                    GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.blueAccent,
              ),
            ],
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Full Name",
              labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                widget.showSnackBar(
                    'Onboarding for ${nameController.text} started!',
                    isSuccess: true);
                nameController.clear();
                setState(() => isExpanded = false);
              } else {
                widget.showSnackBar('Please enter a name.', isError: true);
              }
            },
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: Text("Start Onboarding",
                style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}

// Quick Actions Section
class QuickActionsSection extends StatelessWidget {
  final void Function(String, {bool isSuccess, bool isError}) showSnackBar;

  const QuickActionsSection({super.key, required this.showSnackBar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActionTile(
          icon: Icons.request_page,
          title: 'Requests',
          subtitle: 'View employee requests',
          onTap: () => showSnackBar('Request management coming soon!'),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.lightbulb_outline,
          title: 'Suggestions',
          subtitle: 'Review team ideas',
          onTap: () => showSnackBar('Suggestions board coming soon!'),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.folder_open,
          title: 'Documents',
          subtitle: 'Access HR files',
          onTap: () => showSnackBar('Document access coming soon!'),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
        ],
      ),
    );
  }
}
