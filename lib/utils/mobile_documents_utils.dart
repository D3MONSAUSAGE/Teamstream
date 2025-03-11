// ✅ Mobile-specific utilities (For Android/iOS)
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> downloadFileMobile(
    String fileUrl, String fileName, List<int> bytes) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/$fileName";
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    OpenFile.open(filePath);
  } catch (e) {
    print("❌ Error saving file: $e");
  }
}
