import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/message_repository.dart';

void main() {
  late MessageRepository repository;

  setUp(() {
    repository = MessageRepository();
  });

  group('MessageRepository Tests', () {
    test('should get a message by ID', () async {
      await repository.init();

      final message = await repository.getMessageById(1);

      expect(message, isNotNull);
      expect(message!.id, equals(1));
      expect(message.text, isNotEmpty);
    });

    test('should get messages by relation', () async {
      await repository.init();

      final messages = await repository.getMessagesByRelation('FRIEND');

      expect(messages, isNotEmpty);
      expect(messages.first.relation, equals('FRIEND'));
    });

    test('should return empty list for non-existent relation', () async {
      await repository.init();

      final messages =
          await repository.getMessagesByRelation('INVALID_RELATION');

      expect(messages, isEmpty);
    });

    test('should get all messages', () async {
      await repository.init();

      final messages = await repository.getAllMessages();

      expect(messages, isNotEmpty);
      expect(messages.length, greaterThan(0));
    });

    test('should get random message by relation', () async {
      await repository.init();

      final message = await repository.getRandomMessageByRelation('FRIEND');

      expect(message, isNotNull);
      expect(message!.relation, equals('FRIEND'));
    });

    test('should handle null when getting random message for invalid relation',
        () async {
      await repository.init();

      final message =
          await repository.getRandomMessageByRelation('INVALID_RELATION');

      expect(message, isNull);
    });

    test('should count messages correctly', () async {
      await repository.init();

      final count = await repository.getMessageCount();

      expect(count, greaterThan(0));
    });

    test('should get messages by category', () async {
      await repository.init();

      final messages = await repository.getMessagesByRelation('FRIEND');

      expect(messages, isNotEmpty);
      for (var msg in messages) {
        expect(msg.relation, equals('FRIEND'));
      }
    });
  });
}
