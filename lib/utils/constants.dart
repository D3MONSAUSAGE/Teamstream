import 'package:flutter/foundation.dart' show kIsWeb;

// Set this manually to switch between local and ngrok testing
const bool useNgrok = true; // Enable ngrok
const bool isEmulator = true; // Set for emulator testing

// Use the ngrok URL you provided
const String ngrokUrl = 'https://4959-104-173-28-221.ngrok-free.app';

String getPocketBaseUrl() {
  if (useNgrok) {
    return ngrokUrl; // Use ngrok for all platforms when enabled
  } else if (kIsWeb) {
    // For web (Chrome), use localhost
    return 'http://localhost:8090';
  } else if (isEmulator) {
    // For Android emulator
    return 'http://10.0.2.2:8090';
  } else {
    // For real device (use your machine's local IP)
    return 'http://192.168.1.100:8090';
  }
}

final String pocketBaseUrl = getPocketBaseUrl();
