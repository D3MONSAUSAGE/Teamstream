import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';
import 'package:teamstream/utils/constants.dart';

class DailySalesService {
  static const String collectionName = "daily_sales";

  /// 🔹 Fetch Daily Sales (for reports & dashboards)
  static Future<List<Map<String, dynamic>>> fetchDailySales() async {
    try {
      final records = await BaseService.fetchAll(collectionName);
      print("✅ Fetched ${records.length} daily sales records");
      return records;
    } catch (e) {
      print("❌ Error fetching daily sales: $e");
      return [];
    }
  }

  /// 🔹 Upload & Extract Data from PDF
  static Future<bool> uploadSalesReport(
      PlatformFile file, DateTime dateTime) async {
    try {
      Uint8List fileBytes = file.bytes!;

      // Extract text directly from PDF using Syncfusion
      String extractedText = await _extractTextFromPDF(fileBytes);

      if (extractedText.isEmpty) {
        throw Exception("❌ No readable text found in the sales report.");
      }

      // Extract Sales Data
      Map<String, dynamic> salesData = _parseSalesData(extractedText, dateTime);

      if (salesData.isEmpty) {
        throw Exception("❌ Failed to extract key sales data.");
      }

      // Save to PocketBase
      final record = await BaseService.create(collectionName, salesData);

      if (record != null) {
        print("✅ Sales report uploaded successfully!");
        return true;
      } else {
        throw Exception("❌ Failed to save sales data.");
      }
    } catch (e) {
      print("❌ Error uploading sales report: $e");
      return false;
    }
  }

  /// 🔹 Delete Daily Sale by Date
  static Future<bool> deleteDailySale(DateTime date) async {
    try {
      // Format the date to match the format stored in PocketBase (UTC)
      String formattedDate = DateFormat('yyyy-MM-dd').format(date.toUtc());

      // Fetch the record ID for the given date
      List<Map<String, dynamic>> records =
          await BaseService.fetchAll(collectionName);
      String? recordId;
      for (var record in records) {
        // Compare only the date part of the stored timestamp
        String recordDate =
            record["date"].substring(0, 10); // Extract yyyy-MM-dd
        if (recordDate == formattedDate) {
          recordId = record["id"];
          break;
        }
      }

      if (recordId == null) {
        throw Exception("❌ No record found for the selected date.");
      }

      // Delete the record
      bool success = await BaseService.delete(collectionName, recordId);
      if (success) {
        print("✅ Daily sale deleted successfully!");
        return true;
      } else {
        throw Exception("❌ Failed to delete daily sale.");
      }
    } catch (e) {
      print("❌ Error deleting daily sale: $e");
      return false;
    }
  }

  /// 🔹 Extract Text from PDF using Syncfusion
  static Future<String> _extractTextFromPDF(Uint8List fileBytes) async {
    try {
      // Load the PDF document from bytes
      final pdfDocument = PdfDocument(inputBytes: fileBytes);
      // Extract text for the entire document
      String extractedText = PdfTextExtractor(pdfDocument).extractText();

      // Dispose of the document to free resources
      pdfDocument.dispose();

      print("✅ Extracted PDF Text: $extractedText");
      return extractedText;
    } catch (e) {
      print("❌ Error extracting text from PDF: $e");
      return "";
    }
  }

  /// 🔹 Parse Key Sales Data
  static Map<String, dynamic> _parseSalesData(String text, DateTime dateTime) {
    Map<String, dynamic> extractedData = {};

    try {
      extractedData["gross_sales"] = _extractValue(text, "Gross Sales");
      extractedData["net_sales"] = _extractValue(text, "Net Sales");
      extractedData["total_taxes"] = _extractValue(text, "\\+ Tax");
      extractedData["labor_cost"] = _extractValue(text, "Labor Cost");
      extractedData["order_count"] = _extractValue(text, "Order Count");
      extractedData["labor_hours"] = _extractValue(text, "Labor Hours");
      extractedData["labor_percent"] = _extractValue(text, "Labor Percent");
      extractedData["total_discounts"] = _extractValue(text, "Total Discounts");
      extractedData["voids"] = _extractValue(text, "Voids");
      extractedData["refunds"] = _extractValue(text, "Refunds");
      extractedData["tips_collected"] = _extractValue(text, "- Tips");
      extractedData["cash_sales"] = _extractValue(text, "Cash Sales");
      extractedData["avg_order_value"] = _extractValue(text, "Avg Order Value");
      extractedData["sales_per_labor_hour"] =
          _extractValue(text, "Sales per Labor Hour");

      extractedData["date"] = dateTime.toIso8601String();
    } catch (e) {
      print("❌ Error parsing sales data: $e");
    }

    return extractedData;
  }

  /// 🔹 Extract Numeric Values from PDF Text
  static double _extractValue(String text, String key) {
    try {
      RegExp regex = RegExp("$key\\s*[:]?\\s*\\\$?\\s*([\\d,]+\\.\\d+)");
      Match? match = regex.firstMatch(text);
      if (match != null) {
        print("Matched text for $key: ${match.group(0)}");
        double value = double.parse(match.group(1)!.replaceAll(",", ""));
        print("Extracted $key: $value");
        return value;
      } else {
        print("No match for $key in text");
      }
    } catch (e) {
      print("❌ Failed to extract $key: $e");
    }
    return 0.0;
  }
}
