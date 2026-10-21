import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thème de l'app : clair par défaut, mémorisé entre les lancements.
class ThemeProvider extends ChangeNotifier {
  static const prefsKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.light;

  ThemeProvider() {
    _restore();
  }

  ThemeMode get mode => _mode;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = ThemeMode.values
          .where((m) => m.name == prefs.getString(prefsKey))
          .firstOrNull;
      if (saved != null && saved != _mode) {
        _mode = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  void setMode(ThemeMode m) {
    _mode = m;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setString(prefsKey, m.name))
        .catchError((_) => false);
  }

  /// Bascule entre clair et sombre.
  void toggleTheme() =>
      setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
