import 'dart:io';

// Cleaner script: extract messages from a JS-like seed file into relation|message lines.

final Map<String, String> _categoryMap = {
  'son': 'son',
  'daughter': 'daughter',
  'sister': 'sister',
  'brother': 'brother',
  'friend': 'friend',
  'neighbor': 'neighbor',
  'bestfriend': 'bestfriend',
  'boyfriend': 'boyfriend',
  'girlfriend': 'girlfriend',
  'husband': 'husband',
  'father': 'father',
  'mother': 'mother',
  'auntie': 'auntie',
  'uncle': 'uncle',
  'cousin': 'cousin',
  'niece': 'niece',
  'nephew': 'nephew',
  'grandson': 'grand-son',
  'granddaughter': 'grand-daughter',
  'grandfather': 'grand-father',
  'grandmother': 'grand-mother',
  'godfather': 'god-father',
  'godmother': 'god-mother',
  'best friend': 'bestfriend'
};

String _mapCategory(String name) => _categoryMap[name.toLowerCase()] ?? 'default';

String _normalize(String s) {
  var out = s.replaceAll(RegExp(r'\r\n|\r|\n'), ' ');
  out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
  if ((out.startsWith('"') && out.endsWith('"')) || (out.startsWith("'") && out.endsWith("'"))) {
    out = out.substring(1, out.length - 1);
  }
  return out;
}

Future<void> main() async {
  final projectRoot = Directory.current.path;
  final assetsPath = '$projectRoot\\assets\\messages.txt';
  final backupPath = '$projectRoot\\assets\\messages_original_backup.txt';

  final inFile = File(assetsPath);
  if (!await inFile.exists()) {
    print('assets/messages.txt not found at $assetsPath');
    return;
  }

  final backupFile = File(backupPath);
  if (!await backupFile.exists()) {
    await inFile.copy(backupPath);
    print('Backup written to $backupPath');
  } else {
    final ts = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\.]'), '');
    final alt = '$projectRoot\\assets\\messages_original_backup_$ts.txt';
    await inFile.copy(alt);
    print('Existing backup preserved; wrote new backup to $alt');
  }

  final content = await inFile.readAsString();

  final categoryRegex = RegExp(r'const\s+([A-Za-z0-9_-]+)\s*=\s*\[');
  final keyRegex = RegExp(r'''(?:content|text|message|body|description)
\s*:\s*(?:`|"|')([\s\S]*?)(?:`|"|')''', dotAll: true, multiLine: true);
  final stringLiteralRegex = RegExp(r'''`([\s\S]*?)`|"([\s\S]*?)"|'([\s\S]*?)' ''', dotAll: true, multiLine: true);

  final matches = categoryRegex.allMatches(content).toList();
  final List<String> outLines = [];

  if (matches.isNotEmpty) {
    for (var i = 0; i < matches.length; i++) {
      final name = matches[i].group(1)!;
      final start = matches[i].end;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : content.length;
      final block = content.substring(start, end);
      final relation = _mapCategory(name);

      final keyed = keyRegex.allMatches(block);
      if (keyed.isNotEmpty) {
        for (final k in keyed) {
          final txt = _normalize(k.group(1) ?? '');
          if (txt.isEmpty) continue;
          outLines.add('$relation|${txt.replaceAll('|', '¦')}');
        }
        continue;
      }

      final lits = stringLiteralRegex.allMatches(block);
      for (final m in lits) {
        final raw = m.group(1) ?? m.group(2) ?? m.group(3) ?? '';
        final txt = _normalize(raw);
        if (txt.length < 6) continue;
        if (txt.contains(RegExp(r'https?:\/\/|\.(png|jpg|jpeg|gif)'))) continue;
        outLines.add('$relation|${txt.replaceAll('|', '¦')}');
      }
    }
  } else {
    final keyed = keyRegex.allMatches(content);
    if (keyed.isNotEmpty) {
      for (final k in keyed) {
        final txt = _normalize(k.group(1) ?? '');
        if (txt.isEmpty) continue;
        outLines.add('default|${txt.replaceAll('|', '¦')}');
      }
    } else {
      final lits = stringLiteralRegex.allMatches(content);
      if (lits.isNotEmpty) {
        for (final m in lits) {
          final raw = m.group(1) ?? m.group(2) ?? m.group(3) ?? '';
          final txt = _normalize(raw);
          if (txt.length < 6) continue;
          if (txt.contains(RegExp(r'https?:\/\/|\.(png|jpg|jpeg|gif)'))) continue;
          outLines.add('default|${txt.replaceAll('|', '¦')}');
        }
      } else {
        final lines = content.split(RegExp(r'\r?\n'));
        for (final l in lines) {
          final t = l.trim();
          if (t.isEmpty) continue;
          if (t.startsWith('import ') || t.startsWith('export ') || t.startsWith('const ') || t.startsWith(']') || t.startsWith('{') || t.startsWith('}')) continue;
          final txt = _normalize(t);
          if (txt.isEmpty) continue;
          outLines.add('default|${txt.replaceAll('|', '¦')}');
        }
      }
    }
  }

  final outFile = File(assetsPath);
  final sink = outFile.openWrite();
  for (final l in outLines) sink.writeln(l);
  await sink.close();

  print('Wrote ${outLines.length} cleaned messages to $assetsPath');
  print('Original file backed up at $backupPath');
}
