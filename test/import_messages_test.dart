import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/message_parser.dart';

void main() {
  group('parseMessageLine', () {
    test('current asset format: default|default¦relation¦text', () {
      final m = parseMessageLine(
          "default|default¦son¦Happy birthday, my son! You're my pride.");
      expect(m?.relation, 'son');
      expect(m?.text, "Happy birthday, my son! You're my pride.");
    });

    test('apostrophes are kept (old parser split text on quotes)', () {
      final m = parseMessageLine("default|default¦friend¦Let's celebrate, it's your day!");
      expect(m?.text, "Let's celebrate, it's your day!");
    });

    test('relation|text and JSON lines', () {
      expect(parseMessageLine('FRIEND|Joyeux anniversaire !')?.relation, 'friend');
      final json = parseMessageLine('{"relation":"mother","text":"Love you"}');
      expect(json?.relation, 'mother');
      expect(json?.text, 'Love you');
    });

    test('blank or textless lines are ignored', () {
      expect(parseMessageLine('   '), isNull);
      expect(parseMessageLine('default|default¦son¦  '), isNull);
    });
  });

  test('parseMessagesFile removes duplicates', () {
    final parsed = parseMessagesFile('a|a¦son¦Hi\na|a¦son¦Hi\na|a¦daughter¦Hi\n');
    expect(parsed.length, 2);
  });

  test('the shipped asset parses fully into the app relations', () {
    final content = File('assets/messages.txt').readAsStringSync();
    final parsed = parseMessagesFile(content);
    final relations = parsed.map((m) => m.relation).toSet();

    expect(parsed.length, greaterThan(1000));
    // Relations proposées dans la liste de contacts (en minuscules).
    for (final r in ['son', 'daughter', 'friend', 'mother', 'father',
        'grand-son', 'bestfriend', 'god-mother']) {
      expect(relations, contains(r));
    }
    expect(parsed.any((m) => m.text.contains('¦')), isFalse);
  });

  test('the French asset covers every relation offered in the app', () {
    final relationsEn = parseMessagesFile(
            File('assets/messages.txt').readAsStringSync())
        .map((m) => m.relation)
        .toSet();
    final fr = parseMessagesFile(
        File('assets/messages_fr.txt').readAsStringSync());
    final relationsFr = fr.map((m) => m.relation).toSet();

    expect(relationsFr, contains('default'));
    expect(relationsFr.containsAll(relationsEn), isTrue,
        reason: 'manquent : ${relationsEn.difference(relationsFr)}');
    expect(fr.length, greaterThanOrEqualTo(100));
  });
}
