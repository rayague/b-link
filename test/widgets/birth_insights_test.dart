import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/l10n/zodiac_content.dart';
import 'package:b_link/utils/zodiac.dart';
import 'package:b_link/widgets/birth_insights_widget.dart';

void main() {
  final now = DateTime(2026, 10, 16);
  // 14 octobre 1990 : un dimanche.
  final birth = DateTime(1990, 10, 14);

  test('own profile speaks to the user, in each language', () {
    final fr = birthInsights(birth, now, 'fr');
    expect(fr.first.description, startsWith('Vous avez vu le jour un dimanche.'));
    final en = birthInsights(birth, now, 'en');
    expect(en.first.description, startsWith('You were born on a Sunday.'));
  });

  test("someone else's profile speaks about that person, never to the reader",
      () {
    final named = birthInsights(birth, now, 'fr', personName: 'Awa');
    expect(named.first.description, startsWith('Awa a vu le jour un dimanche.'));
    for (final i in named) {
      expect(i.description.contains('Vous'), isFalse, reason: i.description);
    }
    final anonymous = birthInsights(birth, now, 'en', personName: '');
    expect(anonymous.last.description, startsWith('This person has already lived'));
  });

  test('no northern-hemisphere-only weather claim; seasons name both', () {
    final fr = birthInsights(DateTime(1995, 1, 10), now, 'fr');
    expect(fr.any((i) => i.description.contains('neige')), isFalse);
    final season = fr.firstWhere((i) => i.title == 'Saison de naissance');
    expect(season.description, contains('hémisphère nord'));
    expect(season.description, contains('hémisphère sud'));
    expect(season.description, contains("l'été")); // janvier au sud
  });

  test('every computed sign has content in both languages', () {
    for (var month = 1; month <= 12; month++) {
      for (final day in [1, 15, 28]) {
        final id = Zodiac.computeZodiac(DateTime(2000, month, day));
        for (final lang in ['fr', 'en']) {
          expect(ZodiacContent.of(id), isNotNull, reason: id);
          expect(ZodiacContent.traits(id, lang), hasLength(6));
          expect(ZodiacContent.quotes(id, lang), hasLength(4));
          expect(ZodiacContent.description(id, lang), isNotEmpty);
          expect(ZodiacContent.period(id, lang), isNotEmpty);
        }
      }
    }
    expect(ZodiacContent.name('Bélier', 'en'), 'Aries');
    expect(ZodiacContent.name('Bélier', 'fr'), 'Bélier');
  });
}
