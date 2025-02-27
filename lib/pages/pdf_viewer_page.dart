import 'package:flutter/material.dart';
import 'package:advance_pdf_viewer_fork/advance_pdf_viewer_fork.dart';

class PDFViewerPage extends StatefulWidget {
  final String pdfUrl; // Pass a file URL or path

  const PDFViewerPage({super.key, required this.pdfUrl});

  @override
  PDFViewerPageState createState() => PDFViewerPageState();
}

class PDFViewerPageState extends State<PDFViewerPage> {
  bool _isLoading = true;
  late PDFDocument document;

  @override
  void initState() {
    super.initState();
    loadPDF();
  }

  Future<void> loadPDF() async {
    try {
      document = await PDFDocument.fromURL(widget.pdfUrl); // Load PDF from URL
      setState(() => _isLoading = false);
    } catch (e) {
      print("❌ Error loading PDF: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Viewer")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PDFViewer(document: document),
    );
  }
}
