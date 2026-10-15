// Parser du fichier assets/messages.txt (Dart pur, testable sans Flutter).
//
// Formats acceptés, une ligne par message :
//   default|default¦<relation>¦<texte>   (format actuel du fichier)
//   <relation>|<texte>
//   {"relation": "...", "text": "..."}
// Les lignes vides et celles qui commencent par # sont ignorées.
// Les doublons (même relation et même texte) sont ignorés.

import 'dart:convert';

class ParsedMessage {
  final String relation;
  final String text;
  const ParsedMessage(this.relation, this.text);
}

ParsedMessage? parseMessageLine(String rawLine) {
  final line = rawLine.trim();
  // Lignes vides et commentaires (# titre de section) ignorés.
  if (line.isEmpty || line.startsWith('#')) return null;

  if (line.startsWith('{')) {
    try {
      final map = jsonDecode(line) as Map<String, dynamic>;
      return _build(map['relation']?.toString(), map['text']?.toString());
    } catch (_) {
      return null;
    }
  }

  if (line.contains('¦')) {
    final parts = line.split('¦');
    if (parts.length >= 3) {
      return _build(parts[1], parts.sublist(2).join('¦'));
    }
    return null;
  }

  final pipe = line.indexOf('|');
  if (pipe > 0) {
    return _build(line.substring(0, pipe), line.substring(pipe + 1));
  }
  return _build('default', line);
}

ParsedMessage? _build(String? relation, String? text) {
  final rel = (relation ?? '').trim().toLowerCase();
  final txt = (text ?? '').trim();
  if (txt.isEmpty) return null;
  return ParsedMessage(rel.isEmpty ? 'default' : rel, txt);
}

/// Parse tout le fichier, sans doublons, dans l'ordre d'apparition.
List<ParsedMessage> parseMessagesFile(String content) {
  final seen = <String>{};
  final out = <ParsedMessage>[];
  for (final line in const LineSplitter().convert(content)) {
    final msg = parseMessageLine(line);
    if (msg == null) continue;
    if (seen.add('${msg.relation}\u0000${msg.text}')) out.add(msg);
  }
  return out;
}
