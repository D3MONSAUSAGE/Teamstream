import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';

class PDFViewerScreen extends StatelessWidget {
  final String pdfPath; // Local file path or Web URL

  const PDFViewerScreen({Key? key, required this.pdfPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web → Open in Browser
      return _buildWebPDFViewer(context);
    } else {
      // Mobile → Open with flutter_pdfview
      return _buildMobilePDFViewer(context);
    }
  }

  /// 🔹 Web: Open PDFs in a Browser
  Widget _buildWebPDFViewer(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Viewer (Web)")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            if (await canLaunchUrl(Uri.parse(pdfPath))) {
              await launchUrl(Uri.parse(pdfPath));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Could not open file.")),
              );
            }
          },
          child: const Text("Open PDF in Browser"),
        ),
      ),
    );
  }

  /// 🔹 Mobile: Open PDFs with `flutter_pdfview`
  Widget _buildMobilePDFViewer(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Viewer")),
      body: PDFView(filePath: pdfPath),
    );
  }
}
