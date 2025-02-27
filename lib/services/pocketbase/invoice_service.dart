import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ Needed for opening file URLs
import 'package:teamstream/services/pocketbase/base_service.dart';

class InvoiceService {
  static const String collectionName = "invoices";

  /// 🔹 Upload a new invoice
  static Future<bool> uploadInvoice({
    required String vendor,
    required DateTime date,
    required double amount,
    String? notes,
    required PlatformFile file,
  }) async {
    try {
      // ✅ Prepare Invoice Data
      Map<String, dynamic> invoiceData = {
        "vendor": vendor,
        "date": date.toIso8601String(),
        "amount": amount,
        "notes": notes ?? "",
        "status": "Pending", // Default status
      };

      // ✅ Upload File
      Uint8List fileBytes = file.bytes!;
      final multipartFile = MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: file.name,
      );

      // ✅ Create Invoice Record
      final record = await BaseService.create(collectionName, invoiceData,
          files: [multipartFile]);

      if (record != null) {
        print("✅ Invoice uploaded successfully!");
        return true;
      } else {
        throw Exception("❌ Failed to create invoice record.");
      }
    } catch (e) {
      print("❌ Error uploading invoice: $e");
      return false;
    }
  }

  /// 🔹 Fetch all invoices
  static Future<List<Map<String, dynamic>>> fetchInvoices() async {
    try {
      List<Map<String, dynamic>> invoices =
          await BaseService.fetchAll(collectionName);
      return invoices;
    } catch (e) {
      print("❌ Error fetching invoices: $e");
      return [];
    }
  }

  /// 🔹 Fetch a specific invoice by ID
  static Future<Map<String, dynamic>?> fetchInvoiceById(
      String invoiceId) async {
    try {
      return await BaseService.fetchOne(collectionName, invoiceId);
    } catch (e) {
      print("❌ Error fetching invoice $invoiceId: $e");
      return null;
    }
  }

  /// 🔹 Delete an invoice
  static Future<bool> deleteInvoice(String invoiceId) async {
    try {
      bool success = await BaseService.delete(collectionName, invoiceId);
      if (success) {
        print("✅ Invoice $invoiceId deleted successfully.");
      }
      return success;
    } catch (e) {
      print("❌ Error deleting invoice $invoiceId: $e");
      return false;
    }
  }

  /// 🔹 Update invoice status
  static Future<bool> updateInvoiceStatus(
      String invoiceId, String status) async {
    try {
      bool success = await BaseService.update(collectionName, invoiceId, {
        "status": status,
      });
      if (success) {
        print("✅ Invoice $invoiceId status updated to $status.");
      }
      return success;
    } catch (e) {
      print("❌ Error updating status for invoice $invoiceId: $e");
      return false;
    }
  }

  /// 🔹 Download an invoice file
  static Future<void> downloadInvoice(String fileUrl, String fileName) async {
    try {
      if (await canLaunchUrl(Uri.parse(fileUrl))) {
        await launchUrl(Uri.parse(fileUrl),
            mode: LaunchMode.externalApplication);
        print("✅ Opening invoice file: $fileUrl");
      } else {
        throw Exception("Could not launch $fileUrl");
      }
    } catch (e) {
      print("❌ Error downloading invoice: $e");
    }
  }
}
