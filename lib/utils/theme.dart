import 'package:flutter/material.dart';

class CustomTheme {
  // Define getLightTheme as a getter
  static ThemeData get getLightTheme {
    return ThemeData(
      // Primary color swatch (light green)
      primarySwatch: Colors.green,
      // Scaffold background color (light grey with a hint of green)
      scaffoldBackgroundColor: Colors.grey[50],
      // AppBar theme
      appBarTheme: const AppBarTheme(
        color: Colors.green, // Primary green color for the app bar
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      // Drawer theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white, // Light background for the drawer
      ),
      // Text theme
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87, fontSize: 16),
        headlineSmall: TextStyle(
          color: Colors.green, // Green for headings
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green, // Green buttons
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
        ),
      ),
      // Input decoration theme (for TextFields)
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
          borderSide:
              const BorderSide(color: Colors.green), // Green focus border
        ),
        labelStyle: const TextStyle(color: Colors.green), // Green labels
      ),
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.green, // Green FAB
        elevation: 4,
      ),
      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: Colors.white,
      ),
    );
  }
}
