import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/miles_service.dart';

class MilesPage extends StatefulWidget {
  const MilesPage({super.key});

  @override
  MilesPageState createState() => MilesPageState();
}

class MilesPageState extends State<MilesPage> {
  final TextEditingController milesController = TextEditingController();
  final TextEditingController commentsController = TextEditingController();
  String selectedReason = "Work Assignment";
  Uint8List? selectedImage;
  String payRatePerMile = "0.50"; // Initial value, will be updated
  bool isSubmitting = false;
  bool isDarkMode = false;

  final List<String> travelReasons = [
    "Work Assignment",
    "Client Visit",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    fetchPayRate();
    milesController
        .addListener(() => setState(() {})); // Real-time total update
  }

  Future<void> fetchPayRate() async {
    try {
      final rate = await MilesService.fetchPayRate();
      setState(() => payRatePerMile = rate);
    } catch (e) {
      _showSnackBar('Error fetching pay rate: $e', isError: true);
    }
  }

  Future<void> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.first.bytes != null) {
        setState(() => selectedImage = result.files.first.bytes);
      } else {
        _showSnackBar('No image selected', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  double calculateTotalPay() {
    double miles = double.tryParse(milesController.text) ?? 0;
    double rate = double.tryParse(payRatePerMile) ?? 0;
    return miles * rate;
  }

  Future<void> submitMileage() async {
    double miles = double.tryParse(milesController.text) ?? 0;
    if (miles <= 0) {
      _showSnackBar('Please enter a valid number of miles', isError: true);
      return;
    }

    if (selectedReason.isEmpty || selectedImage == null) {
      _showSnackBar('Please select a reason and upload an image',
          isError: true);
      return;
    }

    String? userId = AuthService.getLoggedInUserId();
    if (userId == null) {
      _showSnackBar('User not logged in', isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      bool success = await MilesService.submitMileage(
        employeeId: userId,
        miles: milesController.text.trim(),
        comments: commentsController.text.trim(),
        reason: selectedReason,
        image: selectedImage!,
        payPerMile: payRatePerMile,
      );

      if (success) {
        _showSnackBar('Mileage submitted successfully', isSuccess: true);
        Navigator.pop(context);
      } else {
        _showSnackBar('Error submitting mileage', isError: true);
      }
    } catch (e) {
      _showSnackBar('Submission failed: $e', isError: true);
    } finally {
      setState(() => isSubmitting = false);
    }
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
  void dispose() {
    milesController.dispose();
    commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'Submit Mileage',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
              onPressed: fetchPayRate,
              tooltip: 'Refresh Pay Rate',
            ),
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => setState(() => isDarkMode = !isDarkMode),
              tooltip: 'Toggle Dark Mode',
            ),
          ],
        ),
        body: isSubmitting
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 12),
                  _buildPayRateCard(),
                  const SizedBox(height: 12),
                  _buildMileageForm(),
                  const SizedBox(height: 12),
                  _buildImageUploadCard(),
                  const SizedBox(height: 12),
                  _buildSubmitButton(),
                ],
              ),
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
              'Mileage Tracker',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submit your travel expenses',
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

  Widget _buildPayRateCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.attach_money, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay Rate Per Mile',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
                Text(
                  '\$$payRatePerMile',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMileageForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mileage Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: milesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Miles Traveled',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                prefixIcon:
                    const Icon(Icons.directions_car, color: Colors.blueAccent),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 12),
            Text(
              'Total Pay: \$${calculateTotalPay().toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedReason,
              items: travelReasons
                  .map((reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason, style: GoogleFonts.poppins()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedReason = value!),
              decoration: InputDecoration(
                labelText: 'Reason for Travel',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                prefixIcon: const Icon(Icons.work, color: Colors.blueAccent),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentsController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Additional Comments',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                prefixIcon: const Icon(Icons.comment, color: Colors.blueAccent),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Proof',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  selectedImage!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.camera_alt, size: 20),
                label: Text(
                  selectedImage == null ? 'Upload Receipt' : 'Change Image',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                  foregroundColor: Colors.blue[900],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : submitMileage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Submit Mileage',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
