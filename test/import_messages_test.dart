import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/db_helper.dart';

void main() {
  group('DBHelper parsing', () {
    test('parse simple JS content', () {
      final content = '''const son = [
  { id: 1, content: "Happy birthday, my son!" },
  { id: 2, content: `Another son message` }
];
''';
      final helper = DBHelper();
      final parsed = helper.parseMessagesFromContent(content);
      expect(parsed.length, 2);
      expect(parsed[0]['relation'], 'son');
      expect(parsed[0]['text'], contains('Happy birthday'));
    });

    test('parse fallback plain lines', () {
      final content = 'Hello world\nJust a message';
      final helper = DBHelper();
      final parsed = helper.parseMessagesFromContent(content);
      expect(parsed.isNotEmpty, true);
    });
  });
}
