import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

const bool isEmulator = true; // Set dynamically or manually for now

String getPocketBaseUrl() {
  if (kIsWeb) {
    // For web (Chrome), use localhost or your machine's IP
    return 'http://localhost:8090'; // Adjust if PocketBase is on a different IP/port
  } else if (isEmulator) {
    return 'http://10.0.2.2:8090'; // For Android emulator
  } else {
    return 'http://192.168.1.100:8090'; // For real device (use your machine's IP)
  }
}

final String pocketBaseUrl = getPocketBaseUrl();
