import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/utils/constants.dart';

class BaseService {
  static final String baseUrl = pocketBaseUrl;

  /// 🔹 Fetch all records from a given collection
  static Future<List<Map<String, dynamic>>> fetchAll(String collection) async {
    try {
      final url = Uri.parse("$baseUrl/api/collections/$collection/records");
      print("🛠️ Fetching all records from URL: $url");

      final response = await http.get(url, headers: _getHeaders());

      print(
          "📡 Response status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('items')) {
          print("✅ Fetched ${data['items'].length} records from $collection");
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
      final url = Uri.parse("$baseUrl/api/collections/$collection/records/$id");
      print("🛠️ Fetching record $id from $collection");

      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        print("✅ Fetched record $id from $collection");
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

  /// 🔹 Fetch records by a specific field value
  static Future<List<Map<String, dynamic>>> fetchByField(
      String collection, String field, String value) async {
    try {
      final url = Uri.parse(
          "$baseUrl/api/collections/$collection/records?filter=($field='$value')");
      print("🛠️ Fetching records from $collection where $field = $value");

      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('items')) {
          print("✅ Fetched ${data['items'].length} records matching filter");
          return List<Map<String, dynamic>>.from(data['items']);
        } else {
          throw Exception("Unexpected response format in fetchByField()");
        }
      } else {
        throw Exception("Failed to fetch records by field: ${response.body}");
      }
    } catch (e) {
      print("❌ Error in fetchByField(): $e");
      return [];
    }
  }

  /// 🔹 Fetch records with a custom filter
  static Future<List<Map<String, dynamic>>> fetchList(String collection,
      {String? filter, String? sort, int? perPage}) async {
    try {
      String queryParams = "";
      if (filter != null && filter.isNotEmpty) {
        final encodedFilter = Uri.encodeQueryComponent(filter);
        queryParams += "?filter=$encodedFilter";
      }
      if (sort != null && sort.isNotEmpty) {
        final encodedSort = Uri.encodeQueryComponent(sort);
        queryParams += "${queryParams.isNotEmpty ? '&' : '?'}sort=$encodedSort";
      }
      if (perPage != null) {
        queryParams += "${queryParams.isNotEmpty ? '&' : '?'}perPage=$perPage";
      }

      final url =
          Uri.parse("$baseUrl/api/collections/$collection/records$queryParams");
      print("🛠️ Fetching records from URL: $url");

      final response = await http.get(url, headers: _getHeaders());

      print(
          "📡 Response status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('items')) {
          print(
              "✅ Fetched ${data['items'].length} records from $collection with filter");
          return List<Map<String, dynamic>>.from(data['items']);
        } else {
          throw Exception("Unexpected response format in fetchList()");
        }
      } else {
        throw Exception("Failed to fetch records: ${response.body}");
      }
    } catch (e) {
      print("❌ Error in fetchList(): $e");
      return [];
    }
  }

  /// 🔹 Create a new record with optional file upload
  static Future<String?> create(String collection, Map<String, dynamic> data,
      {List<dynamic>? files}) async {
    try {
      final url = Uri.parse("$baseUrl/api/collections/$collection/records");
      print("🛠️ Creating record in $collection at URL: $url with data: $data");

      http.Response response;
      if (files != null && files.isNotEmpty) {
        var request = http.MultipartRequest('POST', url);
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });
        print("🛠️ Attaching ${files.length} files to the request");
        await _attachFiles(request, files);
        request.headers.addAll(_getHeaders());
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        response = await http.post(
          url,
          headers: _getHeaders(),
          body: jsonEncode(data),
        );
      }

      print(
          "📡 Create response status: ${response.statusCode}, body: ${response.body}");

      final responseBody = response.body;
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final id = jsonResponse['id'] as String?;
        if (id == null || id.isEmpty) {
          throw Exception("No valid ID returned in response: $responseBody");
        }
        print("✅ Record created with ID: $id");
        return id;
      } else {
        throw Exception(
            "Failed to create record: ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      print("❌ Error in create(): $e");
      rethrow;
    }
  }

  /// 🔹 Update an existing record (Supports Web & Mobile uploads)
  static Future<bool> update(
      String collection, String id, Map<String, dynamic> data,
      {List<dynamic>? files}) async {
    try {
      final url = Uri.parse("$baseUrl/api/collections/$collection/records/$id");
      print("🛠️ Updating record $id in $collection with data: $data");

      if (files != null && files.isNotEmpty) {
        var request = http.MultipartRequest('PATCH', url);
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });
        print("🛠️ Attaching ${files.length} files to the request");
        await _attachFiles(request, files);
        request.headers.addAll(_getHeaders());
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          print("✅ Record $id updated successfully");
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
          print("✅ Record $id updated successfully");
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
      final url = Uri.parse("$baseUrl/api/collections/$collection/records/$id");
      print("🛠️ Deleting record $id from $collection");

      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        print("✅ Record $id deleted successfully");
        return true;
      } else {
        throw Exception("Failed to delete record: ${response.body}");
      }
    } catch (e) {
      print("❌ Error in delete(): $e");
      return false;
    }
  }

  /// 🔹 Helper function to attach files (Supports Mobile & Web)
  static Future<void> _attachFiles(
      http.MultipartRequest request, List<dynamic> files) async {
    for (var file in files) {
      if (file is File) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
        print("🛠️ Attached file: ${file.path}");
      } else if (file is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes('file', file,
            filename: "upload_${DateTime.now().millisecondsSinceEpoch}.png"));
        print("🛠️ Attached file from bytes");
      } else {
        print("⚠️ Warning: Unsupported file type");
      }
    }
  }

  /// 🔹 Helper function to get headers
  static Map<String, String> _getHeaders() {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${AuthService.getToken() ?? ''}"
    };
  }
}
