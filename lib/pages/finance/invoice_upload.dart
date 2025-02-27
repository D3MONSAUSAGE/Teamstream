import 'package:flutter/material.dart';
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
  bool isSubmitting = false; // Prevents multiple submissions

  /// 🔹 Pick Invoice File (PDF, JPG, PNG)
  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      // Prevent large files (Above 5MB)
      if (result.files.single.size > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File size must be under 5MB!")),
        );
        return;
      }

      setState(() {
        selectedFile = result;
      });
    }
  }

  /// 🔹 Pick Invoice Date
  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  /// 🔹 Confirm Submission Before Uploading
  Future<void> _confirmAndSubmit() async {
    if (vendorController.text.isEmpty ||
        selectedDate == null ||
        selectedFile == null ||
        amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    double? amount = double.tryParse(amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid amount entered.")),
      );
      return;
    }

    // Confirm Before Submission
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Invoice Submission"),
        content: Text(
            "Are you sure you want to submit this invoice for ${vendorController.text}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Submit"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _submitInvoice();
    }
  }

  /// 🔹 Submit Invoice to PocketBase
  void _submitInvoice() async {
    setState(() {
      isSubmitting = true;
    });

    bool success = await InvoiceService.uploadInvoice(
      vendor: vendorController.text,
      date: selectedDate!,
      amount: double.parse(amountController.text),
      notes: notesController.text,
      file: selectedFile!.files.single,
    );

    setState(() {
      isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Invoice submitted successfully!")),
      );

      // Clear form after submission
      setState(() {
        vendorController.clear();
        selectedDate = null;
        selectedFile = null;
        amountController.clear();
        notesController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to submit invoice.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Invoice")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor Name Input
            TextField(
              controller: vendorController,
              decoration: InputDecoration(
                labelText: "Vendor Name",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 10),

            // Date Picker
            ListTile(
              title: Text(selectedDate == null
                  ? "Select Invoice Date"
                  : "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}"),
              leading: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),

            // Invoice File Picker
            ListTile(
              title: Text(selectedFile == null
                  ? "Select Invoice File (PDF, JPG, PNG)"
                  : "File: ${selectedFile!.files.single.name}"),
              leading: const Icon(Icons.attach_file),
              onTap: _pickFile,
            ),
            const SizedBox(height: 10),

            // Amount Input
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Total Amount",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 10),

            // Notes Input
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Notes (Optional)",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _confirmAndSubmit,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Invoice"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
