import 'package:flutter/material.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/pages/checklists/checklist_card.dart';
import 'package:teamstream/pages/checklists/add_checklists.dart';
import 'package:teamstream/services/pocketbase/role_service.dart';

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
  bool canCreateChecklists = false; // Tracks if user can create checklists

  // Date range filters
  DateTime? searchStartDate;
  DateTime? searchEndDate;

  @override
  void initState() {
    super.initState();
    _checkPermissions(); // Check user role on load
    _loadChecklists();
  }

  void _checkPermissions() async {
    setState(() {
      canCreateChecklists = RoleService.canCreateChecklists();
    });
  }

  void _loadChecklists() async {
    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> fetchedChecklists =
        await ChecklistsService.fetchChecklists();

    setState(() {
      allChecklists = fetchedChecklists;
      _applyDateFilter();
      isLoading = false;
    });
  }

  void _applyDateFilter() {
    List<Map<String, dynamic>> filtered = allChecklists;

    if (searchStartDate != null) {
      filtered = filtered.where((checklist) {
        if (checklist['start_time'] == null || checklist['start_time'] == "") {
          return false;
        }
        DateTime checklistDate = DateTime.parse(checklist['start_time']);
        return checklistDate.isAtSameMomentAs(searchStartDate!) ||
            checklistDate.isAfter(searchStartDate!);
      }).toList();
    }

    if (searchEndDate != null) {
      filtered = filtered.where((checklist) {
        if (checklist['start_time'] == null || checklist['start_time'] == "") {
          return false;
        }
        DateTime checklistDate = DateTime.parse(checklist['start_time']);
        return checklistDate.isAtSameMomentAs(searchEndDate!) ||
            checklistDate.isBefore(searchEndDate!);
      }).toList();
    }

    // Separate available and completed checklists
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
          ? const Center(child: CircularProgressIndicator())
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
            )
          : null, // Hide if the user doesn't have permission
    );
  }

  Widget _buildChecklistSection(
      String title, List<Map<String, dynamic>> checklists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (checklists.isEmpty)
          const Center(child: Text("No checklists available")),
        ...checklists.map((checklist) => ChecklistCard(
              checklist: checklist,
              onChecklistCompleted: () {
                _loadChecklists();
              },
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
