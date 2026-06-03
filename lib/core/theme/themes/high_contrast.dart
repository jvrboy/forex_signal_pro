import 'package:flutter/material.dart';

class HighContrastTheme {
  HighContrastTheme._();

  static ThemeData build({bool isDark = false}) {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: const Color(0xFF0000FF),
        secondary: const Color(0xFF008000),
        surface: isDark ? Colors.black : Colors.white,
        error: const Color(0xFFFF0000),
        outline: const Color(0xFF000000),
        onPrimary: isDark ? Colors.black : Colors.white,
        onSecondary: isDark ? Colors.black : Colors.white,
        onSurface: isDark ? Colors.white : Colors.black,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? Colors.black : Colors.white,
        elevation: 2,
        shadowColor: isDark ? Colors.white24 : Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? Colors.black : Colors.white,
        selectedItemColor: isDark ? Colors.white : Colors.black,
        unselectedItemColor: isDark ? Colors.white60 : Colors.black54,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.black : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.blue, width: 3),
        ),
        labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        hintStyle: const TextStyle(color: Colors.black54),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 28),
        headlineMedium: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
        bodyMedium: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
        labelLarge: TextStyle(color: const Color(0xFF0000FF), fontWeight: FontWeight.bold, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.black,
        thickness: 2,
        space: 2,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? Colors.black : Colors.white,
        labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? Colors.white : Colors.black,
        contentTextStyle: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
