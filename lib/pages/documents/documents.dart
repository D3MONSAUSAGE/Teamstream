import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamstream/services/pocketbase/documents_service.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:teamstream/pages/documents/document_viewer.dart';
import 'package:file_picker/file_picker.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List<Map<String, dynamic>> documents = [];
  bool isLoading = true;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => isLoading = true);
    try {
      documents = await DocumentsService.fetchDocuments();
    } catch (e) {
      _showSnackBar('Error fetching documents: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openDocument(String fileUrl, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewer(fileUrl: fileUrl, title: fileName),
      ),
    );
  }

  Future<void> _downloadAndOpenFile(String fileUrl, String fileName) async {
    setState(() => isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/$fileName";
      final response = await http.get(Uri.parse(fileUrl));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      await OpenFile.open(filePath);
      _showSnackBar('Document downloaded and opened', isSuccess: true);
    } catch (e) {
      _showSnackBar('Failed to download file: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _uploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'ppt', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => isLoading = true);
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;

        bool success = await DocumentsService.uploadDocument(
          title: fileName,
          description: "Uploaded from app",
          category: "General",
          file: file,
          fileBytes: null,
          fileName: fileName,
        );

        if (success) {
          _showSnackBar('Document uploaded successfully', isSuccess: true);
          await _loadDocuments();
        } else {
          _showSnackBar('Failed to upload document', isError: true);
        }
      } else {
        _showSnackBar('No file selected', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error uploading document: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isSuccess ? Colors.green : (isError ? Colors.red : null),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'Company Documents',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => setState(() => isDarkMode = !isDarkMode),
              tooltip: 'Toggle Dark Mode',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
              onPressed: _loadDocuments,
              tooltip: 'Refresh',
            ),
          ],
        ),
        drawer: const MenuDrawer(),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent))
            : documents.isEmpty
                ? Center(
                    child: Text(
                      'No documents available',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 12),
                      _buildDocumentsList(),
                    ],
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _uploadDocument,
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.upload, color: Colors.white, size: 28),
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
              'Documents Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View and manage company documents',
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

  Widget _buildDocumentsList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Library',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                var doc = documents[index];
                String fileUrl = doc["file"] ?? "";
                String fileName = fileUrl.split('/').last;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: const Icon(Icons.insert_drive_file,
                        color: Colors.blueAccent, size: 24),
                    title: Text(
                      doc["title"],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.blue[900],
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category: ${doc["category"]}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (fileUrl.isNotEmpty)
                          Text(
                            'File: $fileName',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    trailing: fileUrl.isNotEmpty
                        ? PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.grey, size: 20),
                            onSelected: (choice) {
                              if (choice == 'Open') {
                                _openDocument(fileUrl, fileName);
                              } else if (choice == 'Download') {
                                _downloadAndOpenFile(fileUrl, fileName);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'Open',
                                child: Text(
                                  'Open Document',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'Download',
                                child: Text(
                                  'Download Document',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
