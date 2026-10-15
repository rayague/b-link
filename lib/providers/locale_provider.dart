import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Langue de l'app (fr/en), mémorisée entre les lancements. Lue aussi par la
/// tâche d'arrière-plan pour rédiger les rappels dans la bonne langue.
class LocaleProvider extends ChangeNotifier {
  static const prefsKey = 'locale_code';
  static const supported = ['en', 'fr'];

  Locale _locale;

  /// Démarre sur la langue de l'appareil si elle est supportée.
  LocaleProvider({String? deviceLanguage})
      : _locale = Locale(_normalize(deviceLanguage ??
            PlatformDispatcher.instance.locale.languageCode)) {
    _restore();
  }

  Locale get locale => _locale;

  static String _normalize(String code) =>
      supported.contains(code) ? code : 'en';

  /// Langue enregistrée (ou celle de l'appareil) sans passer par l'UI.
  static Future<String> savedLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefsKey);
      if (saved != null) return _normalize(saved);
    } catch (_) {}
    return _normalize(PlatformDispatcher.instance.locale.languageCode);
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefsKey);
      if (saved != null && saved != _locale.languageCode) {
        _locale = Locale(_normalize(saved));
        notifyListeners();
      }
    } catch (_) {}
  }

  void setLocale(Locale locale) {
    _locale = Locale(_normalize(locale.languageCode));
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setString(prefsKey, _locale.languageCode))
        .catchError((_) => false);
  }
}
