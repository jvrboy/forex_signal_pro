import 'package:flutter/material.dart';

class LightTheme {
  LightTheme._();

  static ThemeData build({bool isDark = false}) {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: const Color(0xFF1976D2),
        secondary: const Color(0xFF42A5F5),
        surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        error: const Color(0xFFE53935),
        outline: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: isDark ? Colors.white : const Color(0xFF1A1A2E),
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 1,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? const Color(0xFF424242) : const Color(0xFFE8E8E8), width: 1),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: isDark ? Colors.white54 : const Color(0xFF9E9E9E),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A2E), fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A2E), fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
        bodyLarge: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF333333)),
        bodyMedium: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF666666)),
        labelLarge: TextStyle(color: const Color(0xFF1976D2), fontWeight: FontWeight.w600),
      ),
    );
  }
}
