import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:teamstream/services/pocketbase/warnings_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class WarningsPage extends StatefulWidget {
  const WarningsPage({super.key});

  @override
  _WarningsPageState createState() => _WarningsPageState();
}

class _WarningsPageState extends State<WarningsPage> {
  late WarningsService warningsService;
  List<Map<String, dynamic>> warnings = [];
  List<Map<String, dynamic>> filteredWarnings = [];
  bool isLoading = true;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    warningsService = WarningsService();
    _fetchWarnings();
  }

  Future<void> _fetchWarnings() async {
    setState(() => isLoading = true);
    try {
      warnings = await warningsService.fetchWarnings();
      print("Warnings received in WarningsPage: $warnings");
      _applyDateFilter();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error loading warnings: $e', isError: true);
    }
  }

  void _applyDateFilter() {
    if (startDate == null && endDate == null) {
      filteredWarnings = warnings;
    } else {
      filteredWarnings = warnings.where((warning) {
        final dateIssued = DateTime.parse(warning['date_issued']);
        final start = startDate ?? DateTime(1900);
        final end = endDate ?? DateTime.now();
        return dateIssued.isAfter(start.subtract(const Duration(days: 1))) &&
            dateIssued.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    }
    setState(() {});
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        _applyDateFilter();
      });
    }
  }

  Future<void> _acknowledgeWarning(String warningId) async {
    try {
      final success = await warningsService.acknowledgeWarning(warningId);
      if (success) {
        _showSnackBar('Warning acknowledged successfully!', isSuccess: true);
        await _fetchWarnings(); // Refresh the warnings list
      } else {
        _showSnackBar('Failed to acknowledge warning.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error acknowledging warning: $e', isError: true);
    }
  }

  void _showWarningDetails(Map<String, dynamic> warning) {
    final dateIssued = DateTime.parse(warning['date_issued']);
    final formattedDate = DateFormat('MMM d, yyyy').format(dateIssued);
    final issuedBy = warning['expand']?['issued_by']?['name'] ?? 'Unknown';
    final acknowledged = warning['acknowledged'] == true;
    final acknowledgedAt = warning['acknowledged_at'] != null
        ? DateFormat('MMM d, yyyy')
            .format(DateTime.parse(warning['acknowledged_at']))
        : 'Not acknowledged';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            warning['title'] ?? 'Untitled Warning',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Issued: $formattedDate',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Issued by: $issuedBy',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Description:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  warning['description'] ?? 'No description provided.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acknowledged: ${acknowledged ? 'Yes' : 'No'}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                if (acknowledged)
                  Text(
                    'Acknowledged At: $acknowledgedAt',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                ),
              ),
            ),
            if (!acknowledged)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _acknowledgeWarning(warning['id']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Acknowledge',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isSuccess
            ? Colors.green
            : (isError ? Colors.red : Colors.blueAccent),
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
          'Warnings',
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
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Filter by Date',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : filteredWarnings.isEmpty
              ? Center(
                  child: Text(
                    'No warnings found.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Warnings',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        startDate != null && endDate != null
                            ? 'Warnings from ${DateFormat('MMM d, yyyy').format(startDate!)} to ${DateFormat('MMM d, yyyy').format(endDate!)}'
                            : 'List of warnings issued to you.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...filteredWarnings
                          .map((warning) => _buildWarningCard(warning))
                          .toList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWarningCard(Map<String, dynamic> warning) {
    final dateIssued = DateTime.parse(warning['date_issued']);
    final formattedDate = DateFormat('MMM d, yyyy').format(dateIssued);
    final issuedBy = warning['expand']?['issued_by']?['name'] ?? 'Unknown';
    final acknowledged = warning['acknowledged'] == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _showWarningDetails(warning),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      warning['title'] ?? 'Untitled Warning',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Issued by: $issuedBy',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                warning['description'] ?? 'No description provided.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    acknowledged ? 'Acknowledged' : 'Not Acknowledged',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: acknowledged ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  if (!acknowledged)
                    ElevatedButton(
                      onPressed: () => _acknowledgeWarning(warning['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Acknowledge',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
