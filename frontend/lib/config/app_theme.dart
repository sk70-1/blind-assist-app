import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkAccessibleTheme {
    const primary = Color(0xFF00D1FF);
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFFFFB703),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 20),
        bodyMedium: TextStyle(fontSize: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 64),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
