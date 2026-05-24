import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/theme/app_theme.dart';

enum AppThemeVariant { green, pink }

class ThemeService extends ChangeNotifier {
  static const _prefKey = 'app_theme_variant';

  AppThemeVariant _variant = AppThemeVariant.green;
  bool _ready = false;

  AppThemeVariant get variant => _variant;
  bool get isReady => _ready;
  ThemeData get themeData => AppTheme.fromVariant(_variant);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    _variant = raw == AppThemeVariant.pink.name
        ? AppThemeVariant.pink
        : AppThemeVariant.green;
    _ready = true;
    notifyListeners();
  }

  Future<void> setVariant(AppThemeVariant value) async {
    if (_variant == value) return;
    _variant = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, value.name);
  }
}

extension AppThemeVariantPalette on AppThemeVariant {
  AppPalette get palette =>
      this == AppThemeVariant.pink ? AppPalette.pink : AppPalette.green;
}
