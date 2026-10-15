import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/l10n/app_localizations.dart';
import 'package:b_link/services/message_parser.dart';
import 'package:b_link/utils/relations.dart';

void main() {
  test('relation codes are unique and include WIFE', () {
    expect(kRelations.toSet().length, kRelations.length);
    expect(kRelations, contains('WIFE'));
  });

  for (final lang in ['en', 'fr']) {
    test('every relation has a translated label in $lang', () {
      final l10n = AppLocalizations(Locale(lang));
      final untranslated = [
        for (final code in kRelations)
          if (relationLabel(l10n, code) == code) code,
      ];
      expect(untranslated, isEmpty);
    });
  }

  test('labels are human-readable in French', () {
    final fr = AppLocalizations(const Locale('fr'));
    expect(relationLabel(fr, 'GRAND-MOTHER'), 'Grand-mère');
    expect(relationLabel(fr, 'WIFE'), 'Épouse');
  });

  test('unknown or legacy relation codes are shown as typed', () {
    final en = AppLocalizations(const Locale('en'));
    expect(relationLabel(en, 'COLLEAGUE'), 'COLLEAGUE');
    expect(relationLabel(en, ''), '');
  });

  for (final asset in ['assets/messages.txt', 'assets/messages_fr.txt']) {
    test('$asset has at least 4 messages for every relation', () {
      final counts = <String, int>{};
      for (final m in parseMessagesFile(File(asset).readAsStringSync())) {
        counts[m.relation] = (counts[m.relation] ?? 0) + 1;
      }
      final thin = [
        for (final code in kRelations)
          if ((counts[code.toLowerCase()] ?? 0) < 4)
            '${code.toLowerCase()}=${counts[code.toLowerCase()] ?? 0}',
      ];
      expect(thin, isEmpty);
    });
  }

  test('French messages are well-formed', () {
    final messages =
        parseMessagesFile(File('assets/messages_fr.txt').readAsStringSync());
    for (final m in messages) {
      // Seul {name} est un marqueur valide ; pas de reste de format.
      final placeholders = RegExp(r'\{(\w*)\}').allMatches(m.text);
      expect(placeholders.every((p) => p.group(1) == 'name'), isTrue,
          reason: m.text);
      expect(m.text.contains('|') || m.text.contains('¦'), isFalse,
          reason: m.text);
    }
  });
}
