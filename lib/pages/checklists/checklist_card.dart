import 'package:flutter/material.dart';
import 'package:teamstream/pages/checklists/execute_checklist.dart';
import 'package:teamstream/pages/checklists/revise_checklist.dart';
import 'package:teamstream/services/pocketbase/role_service.dart';

class ChecklistCard extends StatelessWidget {
  final Map<String, dynamic> checklist;
  final VoidCallback onChecklistCompleted;

  const ChecklistCard({
    super.key,
    required this.checklist,
    required this.onChecklistCompleted,
  });

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

  @override
  Widget build(BuildContext context) {
    bool isCompleted = checklist['completed'] ?? false;
    bool isVerified = checklist['verified_by_manager'] ?? false;
    List<String> repeatDays = checklist['repeat_days'] ?? [];

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(checklist['title'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(checklist['description'] ?? "No description available"),
            if (repeatDays.isNotEmpty)
              Text(
                "Repeat Days: ${repeatDays.join(", ")}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted && isVerified)
              const Icon(Icons.check_circle, color: Colors.green),
            if (!RoleService.isManager())
              ElevatedButton(
                onPressed: () {
                  if (!isCompleted) {
                    if (!_isWithinExecutionWindow(checklist)) {
                      String start = checklist['start_time'];
                      String end = checklist['end_time'];
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "This checklist can only be executed between $start and $end"),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExecuteChecklistPage(
                          checklistId: checklist['id'],
                        ),
                      ),
                    ).then((_) {
                      onChecklistCompleted();
                    });
                  } else {
                    if (!isVerified) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviseChecklistPage(
                            checklistId: checklist['id'],
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(isCompleted
                    ? (isVerified ? "Verified" : "Revise")
                    : "Execute"),
              ),
          ],
        ),
      ),
    );
  }
}
