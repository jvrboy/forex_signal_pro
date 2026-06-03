import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_engine.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppTheme>((ref) {
  return ThemeModeNotifier();
});

final brightnessProvider = StateProvider<Brightness>((ref) => Brightness.dark);

class ThemeModeNotifier extends StateNotifier<AppTheme> {
  ThemeModeNotifier() : super(AppTheme.professionalDark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('app_theme') ?? 0;
    if (themeIndex >= 0 && themeIndex < AppTheme.values.length) {
      state = AppTheme.values[themeIndex];
    }
    final brightnessIndex = prefs.getInt('brightness') ?? 1;
    if (brightnessIndex == 0) {
      // brightness will be initialized by the app startup
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme', theme.index);
  }

  Future<void> toggleBrightness(WidgetRef ref) async {
    final current = ref.read(brightnessProvider);
    final newBrightness = current == Brightness.dark ? Brightness.light : Brightness.dark;
    ref.read(brightnessProvider.notifier).state = newBrightness;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('brightness', newBrightness == Brightness.dark ? 1 : 0);
  }
}
