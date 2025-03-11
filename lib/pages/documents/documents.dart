import 'dart:io' show File;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:teamstream/services/pocketbase/documents_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:teamstream/pages/documents/document_viewer.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List<Map<String, dynamic>> documents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  /// 🔹 Fetch documents from PocketBase
  void _loadDocuments() async {
    List<Map<String, dynamic>> fetchedDocs =
        await DocumentsService.fetchDocuments();
    setState(() {
      documents = fetchedDocs;
      isLoading = false;
    });
  }

  /// 🔹 Open documents (Android)
  void _openDocument(String fileUrl, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewer(fileUrl: fileUrl, title: fileName),
      ),
    );
  }

  /// 🔹 Download and Open File (Android-Only)
  Future<void> _downloadAndOpenFile(String fileUrl, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/$fileName";

      final response = await http.get(Uri.parse(fileUrl));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      OpenFile.open(filePath);
    } catch (e) {
      print("❌ Error downloading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download file.")),
      );
    }
  }

  /// 🔹 Upload a Document (Android)
  Future<void> _uploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'ppt', 'txt'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      try {
        bool success = await DocumentsService.uploadDocument(
          title: fileName,
          description: "Uploaded from app",
          category: "General",
          file: file,
          fileBytes: null,
          fileName: fileName,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Document uploaded successfully!")),
          );
          _loadDocuments();
        } else {
          throw Exception("Upload failed.");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error uploading document: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Company Documents"),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _uploadDocument,
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : documents.isEmpty
              ? const Center(child: Text("No documents available."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    var doc = documents[index];
                    String fileUrl = doc["file"] ?? "";
                    String fileName = fileUrl.split('/').last;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file,
                            color: Colors.blueAccent),
                        title: Text(doc["title"],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Category: ${doc["category"]}"),
                            if (fileUrl.isNotEmpty)
                              Text("File: $fileName",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: fileUrl.isNotEmpty
                            ? PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (String choice) {
                                  if (choice == 'Open') {
                                    _openDocument(fileUrl, fileName);
                                  } else if (choice == 'Download') {
                                    _downloadAndOpenFile(fileUrl, fileName);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                      value: 'Open',
                                      child: Text('Open Document')),
                                  const PopupMenuItem(
                                      value: 'Download',
                                      child: Text('Download Document')),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
