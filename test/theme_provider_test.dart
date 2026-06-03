import 'package:flutter_test/flutter_test.dart';
import 'package:forex_signal_pro/core/theme/theme_engine.dart';

void main() {
  group('ThemeEngine', () {
    test('default constructor uses professional dark theme', () {
      final engine = ThemeEngine();
      expect(engine.currentTheme, AppTheme.professionalDark);
      expect(engine.brightness, Brightness.dark);
    });

    test('custom constructor values', () {
      final engine = ThemeEngine(currentTheme: AppTheme.light, brightness: Brightness.light);
      expect(engine.currentTheme, AppTheme.light);
      expect(engine.brightness, Brightness.light);
    });

    test('mode returns correct ThemeMode', () {
      final dark = ThemeEngine(brightness: Brightness.dark);
      final light = ThemeEngine(brightness: Brightness.light);
      expect(dark.mode, ThemeMode.dark);
      expect(light.mode, ThemeMode.light);
    });

    test('lightTheme and darkTheme are ThemeData', () {
      final engine = ThemeEngine();
      expect(engine.lightTheme, isA<ThemeData>());
      expect(engine.darkTheme, isA<ThemeData>());
    });

    test('copyWith preserves unset fields', () {
      final engine = ThemeEngine(currentTheme: AppTheme.liquidGlass, brightness: Brightness.dark);
      final copied = engine.copyWith(brightness: Brightness.light);
      expect(copied.currentTheme, AppTheme.liquidGlass);
      expect(copied.brightness, Brightness.light);
    });

    test('all AppTheme values produce valid theme data', () {
      for (final theme in AppTheme.values) {
        final engine = ThemeEngine(currentTheme: theme);
        expect(engine.lightTheme, isA<ThemeData>());
        expect(engine.darkTheme, isA<ThemeData>());
      }
    });

    test('AppTheme has 4 values', () {
      expect(AppTheme.values.length, 4);
      expect(AppTheme.values, contains(AppTheme.professionalDark));
      expect(AppTheme.values, contains(AppTheme.liquidGlass));
      expect(AppTheme.values, contains(AppTheme.light));
      expect(AppTheme.values, contains(AppTheme.highContrast));
    });
  });
}
