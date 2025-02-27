import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:teamstream/services/pocketbase/base_service.dart';

class DailySalesService {
  static const String collectionName = "daily_sales";

  /// 🔹 Upload & Extract Data from PDF
  static Future<bool> uploadSalesReport(PlatformFile file) async {
    try {
      Uint8List fileBytes = file.bytes!;
      String extractedText = await _extractTextFromPDF(fileBytes);

      if (extractedText.isEmpty) {
        throw Exception("❌ No readable text found in the sales report.");
      }

      // ✅ Extract Sales Data
      Map<String, dynamic> salesData = _parseSalesData(extractedText);

      if (salesData.isEmpty) {
        throw Exception("❌ Failed to extract key sales data.");
      }

      // ✅ Save to PocketBase
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

  /// 🔹 Extract Text from PDF
  static Future<String> _extractTextFromPDF(Uint8List fileBytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: fileBytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      print("❌ Error extracting text from PDF: $e");
      return "";
    }
  }

  /// 🔹 Parse Key Sales Data
  static Map<String, dynamic> _parseSalesData(String text) {
    Map<String, dynamic> extractedData = {};

    try {
      extractedData["gross_sales"] = _extractValue(text, "Gross Sales");
      extractedData["net_sales"] = _extractValue(text, "Net Sales");
      extractedData["total_taxes"] = _extractValue(text, "Total Taxes");
      extractedData["labor_cost"] = _extractValue(text, "Labor Cost");
      extractedData["order_count"] = _extractValue(text, "Order Count");
      extractedData["labor_hours"] = _extractValue(text, "Labor Hours");
      extractedData["labor_percent"] = _extractValue(text, "Labor Percent");
      extractedData["total_discounts"] = _extractValue(text, "Total Discounts");
      extractedData["voids"] = _extractValue(text, "Voids");
      extractedData["refunds"] = _extractValue(text, "Refunds");
      extractedData["tips_collected"] = _extractValue(text, "Tips Collected");
      extractedData["cash_sales"] = _extractValue(text, "Cash Sales");
      extractedData["avg_order_value"] = _extractValue(text, "Avg Order Value");
      extractedData["sales_per_labor_hour"] =
          _extractValue(text, "Sales per Labor Hour");

      extractedData["date"] = DateTime.now().toIso8601String();
    } catch (e) {
      print("❌ Error parsing sales data: $e");
    }

    return extractedData;
  }

  /// 🔹 Extract Numeric Values from PDF Text
  static double _extractValue(String text, String key) {
    try {
      RegExp regex = RegExp("$key\\s*[:\$]?\\s*([\\d,]+\\.\\d+)");
      Match? match = regex.firstMatch(text);
      if (match != null) {
        return double.parse(match.group(1)!.replaceAll(",", ""));
      }
    } catch (e) {
      print("❌ Failed to extract $key: $e");
    }
    return 0.0;
  }

  /// 🔹 Fetch All Daily Sales Data
  static Future<List<Map<String, dynamic>>> fetchSalesData() async {
    try {
      return await BaseService.fetchAll(collectionName);
    } catch (e) {
      print("❌ Error fetching sales data: $e");
      return [];
    }
  }
}
