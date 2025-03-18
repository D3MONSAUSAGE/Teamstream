import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/services/pocketbase/checklists_service.dart';
import 'package:teamstream/services/pocketbase/tasks_service.dart';
import 'package:teamstream/services/pocketbase/role_service.dart';

class ReviseChecklistPage extends StatefulWidget {
  final String checklistId;

  const ReviseChecklistPage({super.key, required this.checklistId});

  @override
  _ReviseChecklistPageState createState() => _ReviseChecklistPageState();
}

class _ReviseChecklistPageState extends State<ReviseChecklistPage> {
  Map<String, dynamic>? checklist;
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    setState(() => isLoading = true);
    try {
      Map<String, dynamic>? fetchedChecklist =
          await ChecklistsService.fetchChecklistById(widget.checklistId);
      if (fetchedChecklist == null) throw Exception("Checklist not found");

      List<Map<String, dynamic>> fetchedTasks =
          await TasksService.fetchTasksByChecklistId(widget.checklistId);

      if (mounted) {
        setState(() {
          checklist = fetchedChecklist;
          tasks = fetchedTasks;
          isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error loading checklist: $e', isError: true);
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleTaskCompletion(int index) async {
    if (!RoleService.canVerifyChecklists()) {
      _showSnackBar('You don’t have permission to revise tasks.',
          isError: true);
      return;
    }

    bool currentStatus = tasks[index]["is_complete"] ?? false;
    setState(() {
      tasks[index]["is_complete"] = !currentStatus;
    });

    try {
      await TasksService.updateTask(
        tasks[index]["id"],
        {"is_complete": tasks[index]["is_complete"]},
      );
    } catch (e) {
      _showSnackBar('Error updating task: $e', isError: true);
      setState(() {
        tasks[index]["is_complete"] = currentStatus; // Revert on error
      });
    }
  }

  Future<void> _completeRevision() async {
    if (!RoleService.canVerifyChecklists()) {
      _showSnackBar('You don’t have permission to verify checklists.',
          isError: true);
      return;
    }

    bool allCompleted =
        tasks.isNotEmpty && tasks.every((task) => task["is_complete"] == true);
    if (!allCompleted) {
      _showSnackBar('Please check off all tasks before verifying.',
          isWarning: true);
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        title: Text(
          'Confirm Verification',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.blue[900],
          ),
        ),
        content: Text(
          'Are you sure you want to verify this checklist?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Verify',
              style: GoogleFonts.poppins(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ChecklistsService.markChecklistVerified(widget.checklistId);
      if (mounted) {
        _showSnackBar('Checklist verified successfully!', isSuccess: true);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Error verifying checklist: $e', isError: true);
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        Widget imageWidget;
        if (kIsWeb) {
          imageWidget = Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                'Failed to load image',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
          );
        } else {
          File file = File(imageUrl);
          imageWidget = !file.existsSync()
              ? Center(
                  child: Text(
                    'Image file not found',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                )
              : Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      'Failed to load image',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  ),
                );
        }
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: InteractiveViewer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: imageWidget,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isSuccess
            ? Colors.green
            : isError
                ? Colors.red
                : isWarning
                    ? Colors.orange
                    : null,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool allTasksCompleted =
        tasks.isNotEmpty && tasks.every((task) => task["is_complete"] == true);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          checklist?["title"] ?? 'Revise Checklist',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _loadChecklist,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : tasks.isEmpty
              ? Center(
                  child: Text(
                    'No tasks available for revision',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 12),
                    _buildTasksList(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: allTasksCompleted ? _completeRevision : null,
        icon: const Icon(Icons.verified, color: Colors.white),
        label: Text(
          'Verify Checklist',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: allTasksCompleted ? Colors.blueAccent : Colors.grey,
      ),
    );
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
              'Checklist Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            if (checklist != null) ...[
              Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatTime(checklist!["start_time"])} - ${_formatTime(checklist!["end_time"])}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.work, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(
                    checklist!["shift"] ?? 'No Shift',
                    style: GoogleFonts.poppins(fontSize: 14),
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
                    checklist!["area"] ?? 'Unknown Area',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks for Revision',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                var task = tasks[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: CheckboxListTile(
                    title: Text(
                      task["name"] ?? 'Unnamed Task',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task["notes"]?.toString().trim().isNotEmpty ??
                            false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '📝 ${task["notes"]}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        if (task["file"] != null &&
                            task["file"].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: GestureDetector(
                              onTap: () => _showFullImage(task["file"]),
                              child: Row(
                                children: [
                                  const Icon(Icons.image,
                                      color: Colors.blueAccent, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'View Uploaded Image',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    value: task["is_complete"] ?? false,
                    onChanged: (value) => _toggleTaskCompletion(index),
                    activeColor: Colors.blueAccent,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String time) {
    try {
      return DateFormat.jm().format(DateTime.parse(time));
    } catch (e) {
      return 'Invalid Time';
    }
  }
}
