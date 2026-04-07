// mobile/lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { minimal, vibrant, premium }

class ThemeProvider with ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.minimal;

  AppThemeMode get mode => _mode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('app_theme') ?? 'minimal';
    _mode = AppThemeMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppThemeMode.minimal,
    );
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', mode.name);
  }
}
