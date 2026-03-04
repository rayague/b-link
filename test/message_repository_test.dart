import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/message_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessageRepository Tests', () {
    test('should create instance without error', () {
      final repository = MessageRepository();
      expect(repository, isNotNull);
    });

    test('getRandomForRelation returns a non-empty string', () async {
      final repository = MessageRepository();
      // In test environment, DB is unavailable so fallback is used
      final message = await repository.getRandomForRelation('FRIEND', 'Alice');
      expect(message, isNotEmpty);
      expect(message, contains('Alice'));
    });

    test('getRandomForRelation substitutes name in fallback', () async {
      final repository = MessageRepository();
      final message =
          await repository.getRandomForRelation('UNKNOWN_RELATION', 'Bob');
      expect(message, contains('Bob'));
    });
  });
}
