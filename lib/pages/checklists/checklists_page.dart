import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/pages/checklists/add_checklists.dart';
import 'package:teamstream/pages/checklists/execute_checklist.dart';
import 'package:teamstream/pages/checklists/revise_checklist.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';
import 'package:teamstream/services/pocketbase/role_service.dart';

class ChecklistsPage extends StatefulWidget {
  const ChecklistsPage({super.key});

  @override
  ChecklistsPageState createState() => ChecklistsPageState();
}

class ChecklistsPageState extends State<ChecklistsPage> {
  List<Map<String, dynamic>> checklists = [];
  bool isLoading = true;
  double executionPercentage = 0.0;
  double revisionPercentage = 0.0;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  Future<void> _loadChecklists() async {
    setState(() => isLoading = true);
    try {
      final fetchedChecklists = await ChecklistsService.fetchChecklists();
      if (mounted) {
        setState(() {
          checklists = fetchedChecklists;
          _calculatePercentages();
          isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error loading checklists: $e', isError: true);
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _calculatePercentages() {
    final dailyChecklists = checklists.where((checklist) {
      try {
        final startTime = DateTime.parse(checklist['start_time']);
        return startTime.year == selectedDate.year &&
            startTime.month == selectedDate.month &&
            startTime.day == selectedDate.day;
      } catch (e) {
        return false;
      }
    }).toList();

    if (dailyChecklists.isEmpty) {
      executionPercentage = 0.0;
      revisionPercentage = 0.0;
      return;
    }

    final total = dailyChecklists.length;
    final executed =
        dailyChecklists.where((c) => c['completed'] == true).length;
    final revised =
        dailyChecklists.where((c) => c['verified_by_manager'] == true).length;

    executionPercentage = (executed / total) * 100;
    revisionPercentage = (revised / total) * 100;
  }

  bool _isWithinExecutionWindow(Map<String, dynamic> checklist) {
    try {
      DateTime start = DateTime.parse(checklist['start_time']);
      DateTime end = DateTime.parse(checklist['end_time']);
      DateTime now = DateTime.now();
      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      return false;
    }
  }

  void _navigateToChecklistPage(Map<String, dynamic> checklist) {
    final bool isCompleted = checklist['completed'] ?? false;
    final bool isVerified = checklist['verified_by_manager'] ?? false;
    final bool canVerify = RoleService.canVerifyChecklists();
    final bool canExecute = RoleService.canExecuteChecklists();
    final bool withinWindow = _isWithinExecutionWindow(checklist);

    if (!isCompleted && canExecute) {
      if (withinWindow) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ExecuteChecklistPage(checklistId: checklist['id']),
          ),
        ).then((_) => _loadChecklists());
      } else {
        _showSnackBar(
          'Execution window: ${_formatTime(checklist['start_time'])} - ${_formatTime(checklist['end_time'])}',
          isWarning: true,
        );
      }
    } else if (isCompleted && !isVerified && canVerify) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ReviseChecklistPage(checklistId: checklist['id']),
        ),
      ).then((_) => _loadChecklists());
    } else {
      _showSnackBar(
        isCompleted && isVerified
            ? 'Checklist already completed and verified'
            : !canExecute && !isCompleted
                ? 'No permission to execute this checklist'
                : !canVerify && isCompleted && !isVerified
                    ? 'No permission to verify this checklist'
                    : 'Checklist not ready for action',
      );
    }
  }

  void _navigateToEditChecklist(Map<String, dynamic> checklist) {
    if (RoleService.canEditChecklists()) {
      showDialog(
        context: context,
        builder: (context) => AddChecklistDialog(
          onChecklistCreated: _loadChecklists,
          checklistToEdit: checklist,
        ),
      );
    } else {
      _showSnackBar('You don’t have permission to edit checklists.',
          isError: true);
    }
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? Colors.green
            : isError
                ? Colors.red
                : isWarning
                    ? Colors.orange
                    : Colors.grey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Checklists',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.calendar_today, color: Colors.white, size: 28),
            onPressed: _pickDate,
            tooltip: 'Select Date',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 12),
                _buildProgressSection(),
                const SizedBox(height: 12),
                _buildChecklistsList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddChecklistDialog(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _calculatePercentages();
      });
    }
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checklists Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage daily tasks and progress',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress for ${DateFormat.yMMMd().format(selectedDate)}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Executed',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: executionPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${executionPercentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revised',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: revisionPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.blueAccent),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${revisionPercentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistsList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Checklists',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            checklists.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'No checklists yet. Add one!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: checklists.length,
                    itemBuilder: (context, index) {
                      return _buildChecklistCard(checklists[index]);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard(Map<String, dynamic> checklist) {
    final bool isCompleted = checklist['completed'] ?? false;
    final bool isVerified = checklist['verified_by_manager'] ?? false;

    return GestureDetector(
      onTap: () => _navigateToChecklistPage(checklist),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      checklist['title'] ?? 'Untitled',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (isCompleted)
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                      if (isVerified)
                        const Icon(Icons.verified,
                            color: Colors.blueAccent, size: 20),
                      if (!isCompleted)
                        const Icon(Icons.circle_outlined,
                            color: Colors.grey, size: 20),
                      if (RoleService.canEditChecklists())
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blueAccent, size: 20),
                          onPressed: () => _navigateToEditChecklist(checklist),
                          tooltip: 'Edit Checklist',
                        ),
                    ],
                  ),
                ],
              ),
              if (checklist['description']?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(
                  checklist['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatTime(checklist['start_time'])} - ${_formatTime(checklist['end_time'])}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.work, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(
                    checklist['shift'] ?? 'No Shift',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(
                    checklist['area'] ?? 'Unknown Area',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
              if (checklist['repeat_daily'] == true) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (checklist['repeat_days'] as List? ?? [])
                      .map((day) => Chip(
                            label: Text(
                              day,
                              style: GoogleFonts.poppins(fontSize: 10),
                            ),
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return 'N/A';
    try {
      return DateFormat.jm().format(DateTime.parse(time));
    } catch (e) {
      return 'Invalid Time';
    }
  }

  void _showAddChecklistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AddChecklistDialog(onChecklistCreated: _loadChecklists),
    );
  }
}
