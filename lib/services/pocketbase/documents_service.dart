import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';
import 'package:http/http.dart' as http;

class DocumentsService {
  static const String collectionName = "documents";
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

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
      // ✅ Step 1: Validate file presence & size
      if (fileBytes == null && file == null) {
        throw Exception("No valid file provided for upload.");
      }
      if (kIsWeb && fileBytes != null && fileBytes.length > maxFileSize) {
        throw Exception("File size exceeds the limit of 10MB.");
      } else if (!kIsWeb && file != null && await file.length() > maxFileSize) {
        throw Exception("File size exceeds the limit of 10MB.");
      }

      // ✅ Step 2: Create document record in PocketBase
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

      // ✅ Step 3: Upload the file (Web vs. Mobile)
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
      }

      print("✅ Document uploaded successfully: $documentId");
      return true;
    } catch (e) {
      print("❌ Error uploading document: $e");
      return false;
    }
  }

  /// 🔹 Update a document (Supports metadata and optional file update)
  static Future<bool> updateDocument({
    required String documentId,
    required String title,
    required String description,
    required String category,
    File? file, // Mobile file
    Uint8List? fileBytes, // Web file
    required String fileName,
  }) async {
    try {
      // ✅ Step 1: Validate file presence & size if a new file is provided
      if (fileBytes != null && kIsWeb && fileBytes.length > maxFileSize) {
        throw Exception("File size exceeds the limit of 10MB.");
      } else if (file != null && !kIsWeb && await file.length() > maxFileSize) {
        throw Exception("File size exceeds the limit of 10MB.");
      }

      // ✅ Step 2: Update document metadata
      Map<String, dynamic> documentData = {
        "title": title,
        "description": description,
        "category": category,
      };

      await BaseService.update(collectionName, documentId, documentData);

      // ✅ Step 3: Upload the new file (if provided)
      if (fileBytes != null && kIsWeb) {
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
      }

      print("✅ Document updated successfully: $documentId");
      return true;
    } catch (e) {
      print("❌ Error updating document: $e");
      return false;
    }
  }

  /// 🔹 Delete a document
  static Future<bool> deleteDocument(String documentId) async {
    try {
      await BaseService.delete(collectionName, documentId);
      print("✅ Document deleted successfully: $documentId");
      return true;
    } catch (e) {
      print("❌ Error deleting document: $e");
      return false;
    }
  }

  /// 🔹 Fetch a single document by ID
  static Future<Map<String, dynamic>?> fetchDocumentById(
      String documentId) async {
    try {
      return await BaseService.fetchOne(collectionName, documentId);
    } catch (e) {
      print("❌ Error fetching document by ID: $e");
      return null;
    }
  }
}
