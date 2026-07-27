// mobile/lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/design_system/theme/app_theme_mode.dart';

// L'enum vit dans le design system (direction des dependances). Reexporte ici
// pour les appelants historiques qui l'importent via ce provider.
export '../core/design_system/theme/app_theme_mode.dart';

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
