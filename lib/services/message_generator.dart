import '../models/contact.dart';

class MessageGenerator {
  static const Map<String, List<String>> _templates = {
    'default': [
      'Happy birthday, {name}! Wishing you a wonderful day.',
      'Happy birthday {name}! Hope you have an amazing day ahead.'
    ],
    'friend': [
      'Hey {name}, happy birthday! Let’s celebrate soon 🎉',
      'Happy birthday to my dear friend {name} — have a blast!'
    ],
    'father': [
      'Happy birthday, Dad ({name}). Thank you for everything.',
      'Wishing you a wonderful birthday, Father. Love you.'
    ]
  };

  static String generate(Contact c) {
    final key = c.relation.toLowerCase();
    final list = _templates[key] ?? _templates['default']!;
    final msg = list[(DateTime.now().millisecondsSinceEpoch % list.length)];
    return msg.replaceAll('{name}', c.name);
  }
}
