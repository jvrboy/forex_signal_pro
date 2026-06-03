import 'package:flutter/material.dart';

class LiquidGlassTheme {
  LiquidGlassTheme._();

  static ThemeData build({bool isDark = true}) {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0EEFF),
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: const Color(0xFF7C4DFF),
        secondary: const Color(0xFF00E5FF),
        surface: isDark ? const Color(0xFF16213E) : const Color(0xFFF5F0FF),
        error: const Color(0xFFFF5252),
        outline: isDark ? const Color(0x33FFFFFF) : const Color(0x33000000),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: isDark ? Colors.white : Colors.black87,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF7C4DFF),
        unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF7C4DFF).withOpacity(0.5),
            width: 2,
          ),
        ),
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
        contentTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: isDark ? Colors.white : Colors.black87),
        bodyLarge: TextStyle(color: isDark ? Colors.white : Colors.black87),
        bodyMedium: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        labelLarge: TextStyle(color: const Color(0xFF7C4DFF), fontWeight: FontWeight.w600),
      ),
    );
  }
}
