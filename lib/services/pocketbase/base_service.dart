import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class BaseService {
  static const String baseUrl = "http://127.0.0.1:8090/api"; // Update if remote

  /// 🔹 Fetch all records from a given collection
  static Future<List<Map<String, dynamic>>> fetchAll(String collection) async {
    final url = Uri.parse("$baseUrl/collections/$collection/records");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('items')) {
        return List<Map<String, dynamic>>.from(data['items']);
      } else {
        throw Exception("Unexpected response format");
      }
    } else {
      throw Exception("Failed to fetch records: ${response.body}");
    }
  }

  /// 🔹 Fetch a single record by ID
  static Future<Map<String, dynamic>> fetchOne(
      String collection, String id) async {
    final url = Uri.parse("$baseUrl/collections/$collection/records/$id");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch record: ${response.body}");
    }
  }

  /// 🔹 Create a new record with optional file upload
  static Future<String?> create(String collection, Map<String, dynamic> data,
      {List<File>? files}) async {
    final url = Uri.parse("$baseUrl/collections/$collection/records");
    var request = http.MultipartRequest('POST', url);

    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (files != null && files.isNotEmpty) {
      for (var file in files) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }
    }

    final response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);
      return jsonResponse['id']; // Return the ID of the created record
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception("Failed to create record: $responseBody");
    }
  }

  /// 🔹 Update an existing record
  static Future<bool> update(
      String collection, String id, Map<String, dynamic> data,
      {List<File>? files}) async {
    final url = Uri.parse("$baseUrl/collections/$collection/records/$id");
    var request = http.MultipartRequest('PATCH', url);

    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (files != null && files.isNotEmpty) {
      for (var file in files) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      return true;
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception("Failed to update record: $responseBody");
    }
  }

  /// 🔹 Delete a record by ID
  static Future<bool> delete(String collection, String id) async {
    final url = Uri.parse("$baseUrl/collections/$collection/records/$id");
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Failed to delete record: ${response.body}");
    }
  }

  /// 🔹 Upload a file to a collection (Supports multiple files)
  static Future<bool> uploadFile(
      String collection, Map<String, dynamic> data, List<File> files) async {
    final url = Uri.parse("$baseUrl/collections/$collection/records");
    var request = http.MultipartRequest('POST', url);

    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    for (var file in files) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception("Failed to upload file: $responseBody");
    }
  }

  /// 🔹 Generate authenticated file URL
  static Future<String> getFileUrl(
      String documentId, String fileName, String authToken) async {
    final url = Uri.parse("$baseUrl/files/documents/$documentId/$fileName");

    // Send a HEAD request to check if authentication is needed
    final response =
        await http.head(url, headers: {"Authorization": "Bearer $authToken"});

    if (response.statusCode == 200) {
      return url.toString(); // ✅ Return file URL if authorized
    } else {
      throw Exception(
          "❌ Unauthorized: You need to be logged in to access this file.");
    }
  }
}
