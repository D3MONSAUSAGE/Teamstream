import 'package:flutter/material.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/pages/checklists/checklist_card.dart';
import 'package:teamstream/pages/checklists/add_checklists.dart';
import 'package:teamstream/services/pocketbase/role_service.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';

class ChecklistsPage extends StatefulWidget {
  const ChecklistsPage({super.key});

  @override
  ChecklistsPageState createState() => ChecklistsPageState();
}

class ChecklistsPageState extends State<ChecklistsPage> {
  List<Map<String, dynamic>> allChecklists = [];
  List<Map<String, dynamic>> availableChecklists = [];
  List<Map<String, dynamic>> completedChecklists = [];
  bool isLoading = true;
  bool canCreateChecklists = false;

  final List<String> managerRoles = [
    RoleService.branchManager,
    RoleService.hospitalityManager,
    RoleService.admin,
  ];

  DateTime? searchStartDate;
  DateTime? searchEndDate;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _loadChecklists();
  }

  void _fetchUserRole() async {
    try {
      String? userRole = await AuthService.getUserRole();
      print("🛠️ Retrieved Role in ChecklistsPage: $userRole");

      if (userRole != null) {
        RoleService.setUserRole(userRole);
      }

      _checkPermissions();
    } catch (e) {
      print("❌ Error fetching user role: $e");
    }
  }

  void _checkPermissions() {
    String? userRole = RoleService.currentUserRole;
    print("🛠️ Current User Role: $userRole");

    setState(() {
      canCreateChecklists = managerRoles.contains(userRole);
      print("🛠️ Can create checklists: $canCreateChecklists");
    });
  }

  void _loadChecklists() async {
    setState(() => isLoading = true);

    try {
      List<Map<String, dynamic>> fetchedChecklists =
          await ChecklistsService.fetchChecklists();
      print("✅ Fetched ${fetchedChecklists.length} checklists");

      setState(() {
        allChecklists = fetchedChecklists;
        _applyDateFilter();
      });
    } catch (e) {
      print("❌ Error loading checklists: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load checklists: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyDateFilter() {
    List<Map<String, dynamic>> filtered = allChecklists;

    if (searchStartDate != null) {
      filtered = filtered.where((checklist) {
        if (checklist['start_time'] == null ||
            checklist['start_time'].isEmpty) {
          return false;
        }
        DateTime checklistDate = DateTime.parse(checklist['start_time']);
        return checklistDate.isAtSameMomentAs(searchStartDate!) ||
            checklistDate.isAfter(searchStartDate!);
      }).toList();
    }

    if (searchEndDate != null) {
      filtered = filtered.where((checklist) {
        if (checklist['start_time'] == null ||
            checklist['start_time'].isEmpty) {
          return false;
        }
        DateTime checklistDate = DateTime.parse(checklist['start_time']);
        return checklistDate.isAtSameMomentAs(searchEndDate!) ||
            checklistDate.isBefore(searchEndDate!);
      }).toList();
    }

    setState(() {
      availableChecklists = filtered
          .where((checklist) => !(checklist['completed'] ?? false))
          .toList();
      completedChecklists = filtered
          .where((checklist) => checklist['completed'] ?? false)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklists'),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: "Select Start Date",
            onPressed: () async {
              DateTime? pickedStart = await showDatePicker(
                context: context,
                initialDate: searchStartDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pickedStart != null) {
                setState(() {
                  searchStartDate = pickedStart;
                  _applyDateFilter();
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.event),
            tooltip: "Select End Date",
            onPressed: () async {
              DateTime? pickedEnd = await showDatePicker(
                context: context,
                initialDate: searchEndDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pickedEnd != null) {
                setState(() {
                  searchEndDate = pickedEnd;
                  _applyDateFilter();
                });
              }
            },
          ),
          if (searchStartDate != null || searchEndDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: "Clear Date Range",
              onPressed: () {
                setState(() {
                  searchStartDate = null;
                  searchEndDate = null;
                  _applyDateFilter();
                });
              },
            ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildChecklistSection(
                    "Available Checklists", availableChecklists),
                const SizedBox(height: 20),
                _buildChecklistSection(
                    "Completed Checklists", completedChecklists),
              ],
            ),
      floatingActionButton: canCreateChecklists
          ? FloatingActionButton.extended(
              onPressed: () {
                _showAddChecklistDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text("Create Checklist"),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildChecklistSection(
      String title, List<Map<String, dynamic>> checklists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (checklists.isEmpty)
          const Center(child: Text("No checklists available")),
        ...checklists.map((checklist) => Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: Colors.blueAccent.withOpacity(0.2), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ChecklistCard(
                checklist: checklist,
                onChecklistCompleted: () {
                  _loadChecklists();
                },
              ),
            )),
      ],
    );
  }

  void _showAddChecklistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddChecklistDialog(
        onChecklistCreated: () {
          _loadChecklists();
        },
      ),
    );
  }
}
