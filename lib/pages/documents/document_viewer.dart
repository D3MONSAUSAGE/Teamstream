import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart'; // For PDF text extraction
import 'package:http/http.dart' as http;

class DocumentViewer extends StatefulWidget {
  final String fileUrl;
  final String title;

  const DocumentViewer({super.key, required this.fileUrl, required this.title});

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  String _pdfText = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfText();
  }

  /// 🔹 Load and extract text from the PDF
  Future<void> _loadPdfText() async {
    try {
      // Download the PDF file
      final response = await http.get(Uri.parse(widget.fileUrl));
      if (response.statusCode == 200) {
        // Load the PDF document
        final pdf = await PdfDocument.openData(response.bodyBytes);

        // Extract text from each page
        String fullText = '';
        for (int i = 1; i <= pdf.pagesCount; i++) {
          try {
            final page = await pdf.getPage(i);
            final pageText = await page.textExtractor.extractText();
            fullText += pageText + "\n"; // Add a newline between pages
          } catch (e) {
            print("Error extracting text from page $i: $e");
            fullText += "\n[Error extracting text from page $i]\n";
          }
        }

        setState(() {
          _pdfText = fullText;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to download PDF: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading PDF: $e");
      setState(() {
        _pdfText = "Error loading PDF: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                _pdfText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
    );
  }
}

extension on PdfPage {
  get textExtractor => null;
}
