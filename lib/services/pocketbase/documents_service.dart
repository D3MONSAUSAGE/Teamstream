import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';
import 'package:http/http.dart' as http;

class DocumentsService {
  static const String collectionName = "documents";

  /// 🔹 Fetch all documents from PocketBase
  static Future<List<Map<String, dynamic>>> fetchDocuments() async {
    try {
      return await BaseService.fetchAll(collectionName);
    } catch (e) {
      print("❌ Error fetching documents: $e");
      return [];
    }
  }

  /// 🔹 Upload a document (Supports Web & Mobile)
  static Future<bool> uploadDocument({
    required String title,
    required String description,
    required String category,
    File? file, // Mobile file
    Uint8List? fileBytes, // Web file
    required String fileName,
  }) async {
    try {
      // Step 1: Create document record in PocketBase
      Map<String, dynamic> documentData = {
        "title": title,
        "description": description,
        "category": category,
      };

      String? documentId =
          await BaseService.create(collectionName, documentData);

      if (documentId == null) {
        throw Exception("❌ Failed to create document record.");
      }

      // Step 2: Upload the file (Mobile vs Web Handling)
      if (kIsWeb && fileBytes != null) {
        // Web File Upload
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        );
        await BaseService.update(collectionName, documentId, {},
            files: [multipartFile]);
      } else if (file != null) {
        // Mobile File Upload
        await BaseService.update(collectionName, documentId, {}, files: [file]);
      } else {
        throw Exception("❌ No valid file provided for upload.");
      }

      print("✅ Document uploaded successfully: $documentId");
      return true;
    } catch (e) {
      print("❌ Error uploading document: $e");
      return false;
    }
  }
}
