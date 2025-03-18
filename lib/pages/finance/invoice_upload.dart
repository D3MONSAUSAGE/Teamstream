import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/services/pocketbase/invoice_service.dart';

class InvoiceUploadPage extends StatefulWidget {
  const InvoiceUploadPage({super.key});

  @override
  InvoiceUploadPageState createState() => InvoiceUploadPageState();
}

class InvoiceUploadPageState extends State<InvoiceUploadPage> {
  final TextEditingController vendorController = TextEditingController();
  DateTime? selectedDate;
  FilePickerResult? selectedFile;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    vendorController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );

      if (result != null) {
        if (result.files.single.size > 5 * 1024 * 1024) {
          _showSnackBar('File size must be under 5MB!', isError: true);
          return;
        }
        if (mounted) {
          setState(() => selectedFile = result);
          _showSnackBar('File selected: ${result.files.single.name}',
              isSuccess: true);
        }
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      setState(() => selectedDate = pickedDate);
    }
  }

  Future<void> _confirmAndSubmit() async {
    if (vendorController.text.isEmpty ||
        selectedDate == null ||
        selectedFile == null ||
        amountController.text.isEmpty) {
      _showSnackBar('Please fill in all required fields.', isError: true);
      return;
    }

    double? amount = double.tryParse(amountController.text);
    if (amount == null) {
      _showSnackBar('Invalid amount entered.', isError: true);
      return;
    }

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        title: Text(
          'Confirm Invoice Submission',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.blue[900],
          ),
        ),
        content: Text(
          'Are you sure you want to submit this invoice for ${vendorController.text}?',
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Submit',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _submitInvoice();
    }
  }

  Future<void> _submitInvoice() async {
    setState(() => isSubmitting = true);

    try {
      bool success = await InvoiceService.uploadInvoice(
        vendor: vendorController.text.trim(),
        date: selectedDate!,
        amount: double.parse(amountController.text),
        notes: notesController.text.trim(),
        file: selectedFile!.files.single,
      );

      if (success) {
        _showSnackBar('Invoice submitted successfully!', isSuccess: true);
        if (mounted) {
          setState(() {
            vendorController.clear();
            selectedDate = null;
            selectedFile = null;
            amountController.clear();
            notesController.clear();
          });
        }
      } else {
        _showSnackBar('Failed to submit invoice.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error submitting invoice: $e', isError: true);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor:
            isSuccess ? Colors.green : (isError ? Colors.red : null),
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
          'Upload Invoice',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: isSubmitting
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice Details',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Submit a new invoice',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: vendorController,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          labelText: 'Vendor Name',
                          labelStyle:
                              GoogleFonts.poppins(color: Colors.grey[700]),
                          prefixIcon: const Icon(Icons.business,
                              color: Colors.blueAccent),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Colors.blueAccent),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.blueAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedDate == null
                                      ? 'Select Invoice Date'
                                      : DateFormat('yyyy-MM-dd')
                                          .format(selectedDate!),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: selectedDate == null
                                        ? Colors.grey[700]
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file,
                                  color: Colors.blueAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedFile == null
                                      ? 'Select Invoice File (PDF, JPG, PNG)'
                                      : 'File: ${selectedFile!.files.single.name}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: selectedFile == null
                                        ? Colors.grey[700]
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          labelText: 'Total Amount',
                          labelStyle:
                              GoogleFonts.poppins(color: Colors.grey[700]),
                          prefixIcon: const Icon(Icons.attach_money,
                              color: Colors.blueAccent),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Colors.blueAccent),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                          labelStyle:
                              GoogleFonts.poppins(color: Colors.grey[700]),
                          prefixIcon:
                              const Icon(Icons.note, color: Colors.blueAccent),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Colors.blueAccent),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _confirmAndSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Submit Invoice',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
