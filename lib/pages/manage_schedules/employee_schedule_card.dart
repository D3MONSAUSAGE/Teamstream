import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/pages/schedules/schedules_page.dart';

class EmployeeScheduleCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final DateTime monday;
  final List<Map<String, dynamic>> employeeShifts;
  final Future<void> Function(String shiftId) onDeleteShift;
  final void Function(Map<String, dynamic> shift) onShowShiftDetails;

  const EmployeeScheduleCard({
    required this.employee,
    required this.monday,
    required this.employeeShifts,
    required this.onDeleteShift,
    required this.onShowShiftDetails,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          employee['name'],
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[900],
          ),
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          ...List.generate(7, (index) {
            final day = monday.add(Duration(days: index));
            final dayShifts = employeeShifts
                .where((s) =>
                    DateTime.parse(s['start_time']).toLocal().isSameDay(day))
                .toList();
            if (dayShifts.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(day),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 8),
                ...dayShifts.map((shift) => _buildShiftCard(shift)).toList(),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> shift) {
    final start = DateTime.parse(shift['start_time']).toLocal();
    final end = DateTime.parse(shift['end_time']).toLocal();
    final hours = end.difference(start).inMinutes / 60;

    return GestureDetector(
      onTap: () => onShowShiftDetails(shift),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${hours.toStringAsFixed(1)}h',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: () => onDeleteShift(shift['id']),
            ),
          ],
        ),
      ),
    );
  }
}
