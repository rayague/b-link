import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/utils/relations.dart';
import 'package:b_link/widgets/greeting_card.dart';

void main() {
  test('card mood follows the relation', () {
    expect(cardMoodFor('WIFE'), CardMood.romantic);
    expect(cardMoodFor('girlfriend'), CardMood.romantic);
    expect(cardMoodFor('BESTFRIEND'), CardMood.friends);
    expect(cardMoodFor('GRAND-MOTHER'), CardMood.family);
    expect(cardMoodFor('default'), CardMood.classic);
    // Toutes les relations proposées ont une ambiance.
    for (final r in kRelations) {
      expect(CardMood.values, contains(cardMoodFor(r)));
    }
  });

  for (final theme in CardMood.values) {
    testWidgets('renders a long message without overflow ($theme)',
        (tester) async {
      final message = List.filled(
              12, 'Que cette année soit douce et lumineuse comme ton sourire.')
          .join(' ');
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: GreetingCard(
              title: 'Joyeux anniversaire Awa !',
              message: message,
              theme: theme),
        ),
      ));
      expect(find.text('Joyeux anniversaire Awa !'), findsOneWidget);
      expect(find.textContaining('B-Link'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
