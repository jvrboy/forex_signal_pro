import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'themes/professional_dark.dart';
import 'themes/liquid_glass.dart';
import 'themes/light_theme.dart';
import 'themes/high_contrast.dart';
import 'providers/theme_provider.dart';

enum AppTheme {
  professionalDark,
  liquidGlass,
  light,
  highContrast,
}

class ThemeEngine {
  final AppTheme currentTheme;
  final Brightness brightness;

  const ThemeEngine({
    this.currentTheme = AppTheme.professionalDark,
    this.brightness = Brightness.dark,
  });

  ThemeData get lightTheme => _buildTheme(false);
  ThemeData get darkTheme => _buildTheme(true);
  ThemeMode get mode => brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark;

  ThemeData _buildTheme(bool isDark) {
    switch (currentTheme) {
      case AppTheme.professionalDark:
        return ProfessionalDarkTheme.build(isDark: isDark);
      case AppTheme.liquidGlass:
        return LiquidGlassTheme.build(isDark: isDark);
      case AppTheme.light:
        return LightTheme.build(isDark: isDark);
      case AppTheme.highContrast:
        return HighContrastTheme.build(isDark: isDark);
    }
  }

  ThemeEngine copyWith({
    AppTheme? currentTheme,
    Brightness? brightness,
  }) {
    return ThemeEngine(
      currentTheme: currentTheme ?? this.currentTheme,
      brightness: brightness ?? this.brightness,
    );
  }
}

final themeEngineProvider = Provider<ThemeEngine>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  final brightness = ref.watch(brightnessProvider);
  return ThemeEngine(
    currentTheme: themeMode,
    brightness: brightness,
  );
});
