import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';

class BaseService {
  static const String baseUrl = "http://127.0.0.1:8090/api"; // Update if remote

  /// 🔹 Fetch all records from a given collection
  static Future<List<Map<String, dynamic>>> fetchAll(String collection) async {
    try {
      final url = Uri.parse("$baseUrl/collections/$collection/records");
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('items')) {
          return List<Map<String, dynamic>>.from(data['items']);
        } else {
          throw Exception("Unexpected response format in fetchAll()");
        }
      } else {
        throw Exception("Failed to fetch records: ${response.body}");
      }
    } catch (e) {
      print("❌ Error in fetchAll(): $e");
      return [];
    }
  }

  /// 🔹 Fetch a single record by ID
  static Future<Map<String, dynamic>?> fetchOne(
      String collection, String id) async {
    try {
      final url = Uri.parse("$baseUrl/collections/$collection/records/$id");
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("⚠️ Warning: No record found for ID $id in $collection");
        return null;
      }
    } catch (e) {
      print("❌ Error in fetchOne(): $e");
      return null;
    }
  }

  /// 🔹 Create a new record with optional file upload
  static Future<String?> create(String collection, Map<String, dynamic> data,
      {List<dynamic>? files}) async {
    try {
      final url = Uri.parse("$baseUrl/collections/$collection/records");
      var request = http.MultipartRequest('POST', url);

      // Ensure user ID is attached when creating records
      String? userId = AuthService.getLoggedInUserId();
      if (userId != null) {
        data["submitted_by"] = userId;
      }

      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (files != null && files.isNotEmpty) {
        await _attachFiles(request, files);
      }

      request.headers.addAll(_getHeaders());

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse['id'];
      } else {
        throw Exception("Failed to create record: $responseBody");
      }
    } catch (e) {
      print("❌ Error in create(): $e");
      return null;
    }
  }

  /// 🔹 Update an existing record (Supports Web & Mobile uploads)
  static Future<bool> update(
      String collection, String id, Map<String, dynamic> data,
      {List<dynamic>? files}) async {
    try {
      final url = Uri.parse("$baseUrl/collections/$collection/records/$id");

      if (files != null && files.isNotEmpty) {
        var request = http.MultipartRequest('PATCH', url);

        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        await _attachFiles(request, files);
        request.headers.addAll(_getHeaders());

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          return true;
        } else {
          throw Exception("Failed to update record: $responseBody");
        }
      } else {
        final response = await http.patch(
          url,
          headers: _getHeaders(),
          body: jsonEncode(data),
        );

        if (response.statusCode == 200) {
          return true;
        } else {
          throw Exception("Failed to update record: ${response.body}");
        }
      }
    } catch (e) {
      print("❌ Error in update(): $e");
      return false;
    }
  }

  /// 🔹 Delete a record by ID
  static Future<bool> delete(String collection, String id) async {
    try {
      final url = Uri.parse("$baseUrl/collections/$collection/records/$id");
      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Failed to delete record: ${response.body}");
      }
    } catch (e) {
      print("❌ Error in delete(): $e");
      return false;
    }
  }

  /// 🔹 Upload a file to a collection (Supports multiple files)
  static Future<bool> uploadFile(
      String collection, Map<String, dynamic> data, List<dynamic> files) async {
    try {
      final url = Uri.parse("$baseUrl/collections/$collection/records");
      var request = http.MultipartRequest('POST', url);

      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      await _attachFiles(request, files);
      request.headers.addAll(_getHeaders());

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception("Failed to upload file: $responseBody");
      }
    } catch (e) {
      print("❌ Error in uploadFile(): $e");
      return false;
    }
  }

  /// 🔹 Generate authenticated file URL
  static Future<String> getFileUrl(
      String documentId, String fileName, String authToken) async {
    try {
      final url = Uri.parse("$baseUrl/files/documents/$documentId/$fileName");
      final response =
          await http.head(url, headers: {"Authorization": "Bearer $authToken"});

      if (response.statusCode == 200) {
        return url.toString();
      } else {
        throw Exception("Unauthorized: Unable to access file.");
      }
    } catch (e) {
      print("❌ Error in getFileUrl(): $e");
      throw Exception("Failed to retrieve file URL.");
    }
  }

  /// 🔹 Helper function to attach files (Supports Mobile & Web)
  static Future<void> _attachFiles(
      http.MultipartRequest request, List<dynamic> files) async {
    for (var file in files) {
      if (file is File) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      } else if (file is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes('file', file,
            filename: "upload_${DateTime.now().millisecondsSinceEpoch}.png"));
      } else {
        print("⚠️ Warning: Unsupported file type");
      }
    }
  }

  /// 🔹 Helper function to get headers
  static Map<String, String> _getHeaders() {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${AuthService.getLoggedInUserId() ?? ''}"
    };
  }
}
