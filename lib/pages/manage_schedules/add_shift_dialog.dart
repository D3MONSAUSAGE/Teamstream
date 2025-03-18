import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddShiftDialog extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  final Future<void> Function({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) onAddShift;

  const AddShiftDialog(
      {required this.employees, required this.onAddShift, super.key});

  @override
  State<AddShiftDialog> createState() => _AddShiftDialogState();
}

class _AddShiftDialogState extends State<AddShiftDialog> {
  String? _userId;
  DateTime? _startTime;
  DateTime? _endTime;
  final _notesController = TextEditingController();
  String? _errorMessage;
  double? _projectedHours;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime({bool isEndTime = false}) async {
    DateTime initialDate = DateTime.now();
    if (isEndTime && _startTime != null) {
      initialDate = _startTime!;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isEndTime && _startTime != null
          ? _startTime!
          : DateTime.now().subtract(const Duration(days: 30)),
      lastDate: isEndTime && _startTime != null
          ? _startTime!.add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent)),
        child: child!,
      ),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent)),
        child: child!,
      ),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _calculateProjectedHours() {
    if (_startTime != null && _endTime != null) {
      if (_endTime!.isBefore(_startTime!)) {
        setState(() {
          _errorMessage = 'End time cannot be before start time';
          _projectedHours = null;
        });
      } else {
        final duration = _endTime!.difference(_startTime!);
        setState(() {
          _projectedHours = duration.inMinutes / 60.0;
          _errorMessage = null;
        });
      }
    } else {
      setState(() {
        _projectedHours = null;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Add Shift',
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, color: Colors.blue[900]),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _userId,
              decoration: InputDecoration(
                labelText: 'Employee',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
              ),
              items: widget.employees
                  .map((e) => DropdownMenuItem(
                        value: e['id'] as String,
                        child: Text(e['name'] as String,
                            style: GoogleFonts.poppins()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _userId = value),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final picked = await _pickDateTime();
                if (picked != null) {
                  setState(() {
                    _startTime = picked;
                    if (_endTime != null && _endTime!.isBefore(_startTime!)) {
                      _endTime = null;
                    }
                    _calculateProjectedHours();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _startTime == null
                    ? 'Select Start Time'
                    : DateFormat('MMM d, h:mm a').format(_startTime!),
                style: GoogleFonts.poppins(color: Colors.blue[900]),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _startTime == null
                  ? null
                  : () async {
                      final picked = await _pickDateTime(isEndTime: true);
                      if (picked != null) {
                        setState(() {
                          _endTime = picked;
                          _calculateProjectedHours();
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _endTime == null
                    ? 'Select End Time'
                    : DateFormat('MMM d, h:mm a').format(_endTime!),
                style: GoogleFonts.poppins(color: Colors.blue[900]),
              ),
            ),
            const SizedBox(height: 12),
            if (_projectedHours != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Projected Hours: ${_projectedHours!.toStringAsFixed(1)}h',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
              ),
              maxLines: 2,
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[700])),
        ),
        ElevatedButton(
          onPressed: _userId != null &&
                  _startTime != null &&
                  _endTime != null &&
                  _errorMessage == null
              ? () {
                  widget.onAddShift(
                    userId: _userId!,
                    startTime: _startTime!,
                    endTime: _endTime!,
                    notes: _notesController.text.isEmpty
                        ? null
                        : _notesController.text,
                  );
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Add Shift',
              style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    );
  }
}
