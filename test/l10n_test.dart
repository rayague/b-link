import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/l10n/app_localizations.dart';

/// `translate` renvoie la clé brute quand elle est absente : l'utilisateur voit
/// alors "publicProfile" ou "month_january" à l'écran. Ce test vérifie que
/// toute clé utilisée dans lib/ existe en anglais et en français.
void main() {
  final usedKeys = <String, String>{};
  final pattern = RegExp(r"translate\(\s*'([A-Za-z0-9_]+)'\s*\)");
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    for (final m in pattern.allMatches(entity.readAsStringSync())) {
      usedKeys.putIfAbsent(m.group(1)!, () => entity.path);
    }
  }

  test('lib/ uses translation keys', () {
    expect(usedKeys.length, greaterThan(100));
  });

  for (final lang in ['en', 'fr']) {
    test('every key used in lib/ is translated in $lang', () {
      final l10n = AppLocalizations(Locale(lang));
      final missing = [
        for (final e in usedKeys.entries)
          if (l10n.translate(e.key) == e.key) '${e.key} (${e.value})',
      ];
      expect(missing, isEmpty);
    });
  }
}
