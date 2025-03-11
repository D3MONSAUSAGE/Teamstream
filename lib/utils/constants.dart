// lib/constants.dart
const bool isEmulator = true; // Set this dynamically based on your environment

String getPocketBaseUrl() {
  if (isEmulator) {
    return 'http://10.0.2.2:8090'; // For Android emulator
  } else {
    return 'http://192.168.1.100:8090'; // For real device (replace with your machine's IP)
  }
}

final String pocketBaseUrl = getPocketBaseUrl();
