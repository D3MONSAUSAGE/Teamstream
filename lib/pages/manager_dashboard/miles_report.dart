import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/miles_service.dart';
import 'package:teamstream/utils/constants.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class MilesReportPage extends StatefulWidget {
  const MilesReportPage({super.key});

  @override
  _MilesReportPageState createState() => _MilesReportPageState();
}

class _MilesReportPageState extends State<MilesReportPage> {
  List<Map<String, dynamic>> mileageReports = [];
  bool isLoadingReports = true;
  bool isLoadingPayRate = true;
  String payRatePerMile = "0.50";
  final TextEditingController payRateController = TextEditingController();
  bool isUpdatingPayRate = false;

  @override
  void initState() {
    super.initState();
    _fetchMileageReports();
    _fetchPayRate();
  }

  Future<void> _fetchMileageReports() async {
    setState(() => isLoadingReports = true);
    try {
      mileageReports = await MilesService.fetchMileageReports();
      print("Mileage reports received: $mileageReports");
      setState(() => isLoadingReports = false);
    } catch (e) {
      setState(() => isLoadingReports = false);
      _showSnackBar('Error loading mileage reports: $e', isError: true);
    }
  }

  Future<void> _fetchPayRate() async {
    setState(() => isLoadingPayRate = true);
    try {
      payRatePerMile = await MilesService.fetchPayRate();
      payRateController.text = payRatePerMile;
      setState(() => isLoadingPayRate = false);
    } catch (e) {
      setState(() => isLoadingPayRate = false);
      _showSnackBar('Error loading pay rate: $e', isError: true);
    }
  }

  Future<void> _updatePayRate() async {
    final newRate = payRateController.text.trim();
    if (newRate.isEmpty || double.tryParse(newRate) == null) {
      _showSnackBar('Please enter a valid pay rate', isError: true);
      return;
    }

    setState(() => isUpdatingPayRate = true);
    try {
      print('Attempting to update pay rate to: $newRate');
      final success = await MilesService.updatePayRate(newRate);
      if (success) {
        setState(() => payRatePerMile = newRate);
        _showSnackBar('Global pay rate updated successfully!', isSuccess: true);
      } else {
        _showSnackBar('Failed to update global pay rate.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error updating global pay rate: $e', isError: true);
    } finally {
      setState(() => isUpdatingPayRate = false);
    }
  }

  Future<void> _approveMileage(String recordId) async {
    final userId = AuthService.getLoggedInUserId();
    if (userId == null) {
      _showSnackBar('User not logged in', isError: true);
      return;
    }

    try {
      final success =
          await MilesService.updateMileageStatus(recordId, 'APPROVED', userId);
      if (success) {
        _showSnackBar('Mileage approved successfully!', isSuccess: true);
        await _fetchMileageReports(); // Refresh the reports
      } else {
        _showSnackBar('Failed to approve mileage.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error approving mileage: $e', isError: true);
    }
  }

  Future<void> _denyMileage(String recordId) async {
    final userId = AuthService.getLoggedInUserId();
    if (userId == null) {
      _showSnackBar('User not logged in', isError: true);
      return;
    }

    try {
      final success =
          await MilesService.updateMileageStatus(recordId, 'DENIED', userId);
      if (success) {
        _showSnackBar('Mileage denied successfully!', isSuccess: true);
        await _fetchMileageReports(); // Refresh the reports
      } else {
        _showSnackBar('Failed to deny mileage.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error denying mileage: $e', isError: true);
    }
  }

  Future<void> _editPayRateForRecord(
      String recordId, String currentPayRate, String miles) async {
    final TextEditingController editPayRateController =
        TextEditingController(text: currentPayRate);
    bool isUpdating = false;

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
                'Edit Pay Rate for Record',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editPayRateController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Pay Rate Per Mile (\$)',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                ],
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
                  onPressed: isUpdating
                      ? null
                      : () async {
                          setDialogState(() => isUpdating = true);
                          final newRate = editPayRateController.text.trim();
                          if (newRate.isEmpty ||
                              double.tryParse(newRate) == null) {
                            _showSnackBar('Please enter a valid pay rate',
                                isError: true);
                            setDialogState(() => isUpdating = false);
                            return;
                          }

                          try {
                            final success =
                                await MilesService.updateMileagePayRate(
                                    recordId, newRate, miles);
                            if (success) {
                              _showSnackBar('Pay rate updated successfully!',
                                  isSuccess: true);
                              await _fetchMileageReports(); // Refresh the reports
                              Navigator.pop(context);
                            } else {
                              _showSnackBar('Failed to update pay rate.',
                                  isError: true);
                            }
                          } catch (e) {
                            _showSnackBar('Error updating pay rate: $e',
                                isError: true);
                          } finally {
                            setDialogState(() => isUpdating = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Update',
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
    final isAdmin = (AuthService.getRole() ?? '').toLowerCase() == 'admin';
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Mileage Reports',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MenuDrawer(),
      body: isLoadingReports || isLoadingPayRate
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mileage Reports',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View and manage mileage submissions.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isAdmin) ...[
                    _buildPayRateSettingsCard(),
                    const SizedBox(height: 20),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text(
                        'Editing options are only available to admins.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  _buildReportsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildPayRateSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pay Rate Settings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: payRateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Global Pay Rate Per Mile (\$)',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUpdatingPayRate ? null : _updatePayRate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isUpdatingPayRate
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Update Global Pay Rate',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mileage Submissions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.blue[900],
          ),
        ),
        const SizedBox(height: 12),
        mileageReports.isEmpty
            ? Center(
                child: Text(
                  'No mileage reports found.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              )
            : Column(
                children: mileageReports
                    .map((report) => _buildReportCard(report))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final employeeName = report['expand']?['employee']?['name'] ?? 'Unknown';
    final approverName = report['expand']?['approved_by']?['name'] ?? 'N/A';
    final dateSubmitted = DateTime.parse(report['created']);
    final formattedDate = DateFormat('MMM d, yyyy').format(dateSubmitted);
    final miles = double.parse(report['miles']);
    final payPerMile = double.parse(report['pay_per_mile']);
    final totalPay = double.parse(report['total_pay']);
    final status = report['status'] ?? 'PENDING';
    final isAdmin = (AuthService.getRole() ?? '').toLowerCase() == 'admin';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
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
                    'Employee: $employeeName',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
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
              'Miles: $miles',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: ${report['reason']}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pay Per Mile: \$${payPerMile.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                if (isAdmin)
                  TextButton(
                    onPressed: () => _editPayRateForRecord(
                      report['id'],
                      report['pay_per_mile'],
                      report['miles'],
                    ),
                    child: Text(
                      'Edit Pay Rate',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total Pay: \$${totalPay.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comments: ${report['comments'] ?? 'None'}',
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
                  'Status: $status',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: status == 'APPROVED'
                        ? Colors.green
                        : (status == 'DENIED'
                            ? Colors.redAccent
                            : Colors.orange),
                  ),
                ),
                if (isAdmin && status == 'PENDING') ...[
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _approveMileage(report['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Approve',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _denyMileage(report['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Deny',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (status != 'PENDING' && approverName != 'N/A')
              Text(
                'Approved/Denied by: $approverName',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            if (report['mileage_photo'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    "$pocketBaseUrl/api/files/miles/${report['id']}/${report['mileage_photo']}",
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'Failed to load image',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
