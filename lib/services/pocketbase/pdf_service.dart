import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:teamstream/services/pocketbase/base_service.dart';

class PDFService {
  static const String collectionName = "pdf_files";

  /// 🔹 Upload a new PDF
  static Future<bool> uploadPDF(PlatformFile file) async {
    try {
      Uint8List fileBytes = file.bytes!;
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: file.name,
      );

      Map<String, dynamic> pdfData = {
        "name": file.name,
        "date": DateTime.now().toIso8601String(),
      };

      final record = await BaseService.create(collectionName, pdfData,
          files: [multipartFile]);

      if (record != null) {
        print("✅ PDF uploaded successfully!");
        return true;
      } else {
        throw Exception("❌ Failed to upload PDF.");
      }
    } catch (e) {
      print("❌ Error uploading PDF: $e");
      return false;
    }
  }

  /// 🔹 Fetch all PDFs
  static Future<List<Map<String, dynamic>>> fetchPDFs() async {
    try {
      List<Map<String, dynamic>> pdfs =
          await BaseService.fetchAll(collectionName);
      return pdfs;
    } catch (e) {
      print("❌ Error fetching PDFs: $e");
      return [];
    }
  }
}
