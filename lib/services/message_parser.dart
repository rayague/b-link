// Pure Dart parser for messages file. No Flutter or platform plugins used here.

List<Map<String,String>> parseMessagesFromContent(String content) {
  final List<Map<String,String>> out = [];
  final categoryRegex = RegExp(r'const\s+([A-Za-z0-9_-]+)\s*=\s*\[');
  final matches = categoryRegex.allMatches(content).toList();
  // keys that commonly hold message text in various seeds
  final keyPatterns = ['content', 'text', 'message', 'body', 'description'];
  // Build patterns with escaped backslashes so Dart string parsing works reliably
  final keyPatternStr = '(?:(?:' + keyPatterns.join('|') + '))\\s*:\\s*(?:`|"|\')([\\s\\S]*?)(?:`|"|\')';
  final keyRegex = RegExp(keyPatternStr, dotAll: true, multiLine: true);
  final stringLiteralPattern = '`([\\s\\S]*?)`|"([\\s\\S]*?)"|\'([\\s\\S]*?)\'';
  final stringLiteralRegex = RegExp(stringLiteralPattern, dotAll: true, multiLine: true);

  if (matches.isNotEmpty) {
    for (var i = 0; i < matches.length; i++) {
      final name = matches[i].group(1)!;
      final start = matches[i].end;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : content.length;
      final block = content.substring(start, end);
      final relation = _mapCategoryToRelation(name);

      // 1) try keyed patterns first (content:, text:, message:...)
      final keyed = keyRegex.allMatches(block);
      if (keyed.isNotEmpty) {
        for (final it in keyed) {
          final txt = normalizeForParse(it.group(1)!);
          if (txt.isEmpty) continue;
          out.add({'relation': relation, 'text': txt});
        }
        continue;
      }

      // 2) fallback: capture any string literals inside the block (likely array of messages)
      final lits = stringLiteralRegex.allMatches(block);
      for (final m in lits) {
        final txt = normalizeForParse(m.group(1) ?? m.group(2) ?? m.group(3) ?? '');
        if (txt.isEmpty) continue;
        // heuristics: skip short tokens or tokens that look like urls/path or single words like 'content'
        if (txt.length < 6) continue;
        if (txt.contains(RegExp(r'https?:\/\/|\.(png|jpg|jpeg|gif)'))) continue;
        out.add({'relation': relation, 'text': txt});
      }
    }
  } else {
    // global search across file: try keyed patterns first
    final keyed = keyRegex.allMatches(content);
    if (keyed.isNotEmpty) {
      for (final it in keyed) {
        final txt = normalizeForParse(it.group(1)!);
        if (txt.isEmpty) continue;
        out.add({'relation': 'default', 'text': txt});
      }
    } else {
      // last fallback: collect all string literals across the file
      final lits = stringLiteralRegex.allMatches(content);
      for (final m in lits) {
        final txt = normalizeForParse(m.group(1) ?? m.group(2) ?? m.group(3) ?? '');
        if (txt.isEmpty) continue;
        if (txt.length < 6) continue;
        if (txt.contains(RegExp(r'https?:\/\/|\.(png|jpg|jpeg|gif)'))) continue;
        out.add({'relation': 'default', 'text': txt});
      }
      // fallback 2: plain-line fallback for files that are just newline-separated messages
      if (out.isEmpty) {
        for (final line in content.split(RegExp(r'\r\n|\r|\n'))) {
          final txt = normalizeForParse(line);
          if (txt.isEmpty) continue;
          if (txt.length < 6) continue;
          if (txt.contains(RegExp(r'https?:\/\/|\.(png|jpg|jpeg|gif)'))) continue;
          out.add({'relation': 'default', 'text': txt});
        }
      }
    }
  }
  return out;
}

String normalizeForParse(String s) {
  var out = s.replaceAll(RegExp(r'\r\n|\r|\n'), ' ');
  out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
  if ((out.startsWith('"') && out.endsWith('"')) || (out.startsWith("'") && out.endsWith("'"))) {
    out = out.substring(1, out.length-1);
  }
  return out;
}

String _mapCategoryToRelation(String cat) {
  final m = cat.toLowerCase();
  final map = {
    'son': 'son',
    'daughter':'daughter',
    'sister':'sister',
    'brother':'brother',
    'friend':'friend',
    'neighbor':'neighbor',
    'bestfriend':'bestfriend',
    'boyfriend':'boyfriend',
    'girlfriend':'girlfriend',
    'husband':'husband',
    'father':'father',
    'mother':'mother',
    'auntie':'auntie',
    'uncle':'uncle',
    'cousin':'cousin',
    'niece':'niece',
    'nephew':'nephew',
    'grandson':'grand-son',
    'granddaughter':'grand-daughter',
    'grandfather':'grand-father',
    'grandmother':'grand-mother',
    'godfather':'god-father',
    'godmother':'god-mother',
    'best friend':'bestfriend'
  };
  return map[m] ?? 'default';
}
