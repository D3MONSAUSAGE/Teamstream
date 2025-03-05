import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewer extends StatelessWidget {
  final String fileUrl;
  final String title;

  const DocumentViewer({super.key, required this.fileUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildWebView(context),
    );
  }

  Widget _buildWebView(BuildContext context) {
    if (kIsWeb) {
      // Web → Use iframe viewer
      return Center(
        child: Column(
          children: [
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(
                      "https://docs.google.com/gview?embedded=true&url=$fileUrl"),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse(fileUrl)),
              icon: const Icon(Icons.open_in_new),
              label: const Text("Open in New Tab"),
            ),
          ],
        ),
      );
    } else {
      // Mobile → Try WebView, but fallback to Google Docs Viewer
      return InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(fileUrl.endsWith('.pdf')
              ? "https://docs.google.com/gview?embedded=true&url=$fileUrl"
              : fileUrl),
        ),
      );
    }
  }
}
