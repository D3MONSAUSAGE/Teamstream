import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teamstream/services/pocketbase/pdf_service.dart';

class PDFUploadPage extends StatefulWidget {
  const PDFUploadPage({super.key});

  @override
  PDFUploadPageState createState() => PDFUploadPageState();
}

class PDFUploadPageState extends State<PDFUploadPage> {
  PlatformFile? selectedFile;

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

  void _uploadFile() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please select a file first.")),
      );
      return;
    }

    bool success = await PDFService.uploadPDF(selectedFile!);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ PDF uploaded successfully!")),
      );
      setState(() {
        selectedFile = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to upload PDF.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload PDF")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text(selectedFile == null
                  ? "Select PDF File"
                  : "File: ${selectedFile!.name}"),
              leading: const Icon(Icons.attach_file),
              onTap: _pickFile,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _uploadFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload PDF"),
            ),
          ],
        ),
      ),
    );
  }
}
