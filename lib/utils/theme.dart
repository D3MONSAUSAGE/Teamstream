import 'package:flutter/material.dart';

class CustomTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.grey[100],
      appBarTheme: const AppBarTheme(
        color: Colors.blueAccent,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87, fontSize: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }
}
