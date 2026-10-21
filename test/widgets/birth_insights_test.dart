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
    expect(fr.first.description, startsWith('Vous êtes né(e) un dimanche.'));
    expect(fr.first.description, contains('dies dominicus'));
    final en = birthInsights(birth, now, 'en');
    expect(en.first.description, startsWith('You were born on a Sunday.'));
  });

  test("someone else's profile speaks about that person, never to the reader",
      () {
    final named = birthInsights(birth, now, 'fr', personName: 'Awa');
    expect(named.first.description, startsWith('Awa est né(e) un dimanche.'));
    for (final i in named) {
      expect(i.description.contains('Vous'), isFalse, reason: i.description);
    }
    final anonymous = birthInsights(birth, now, 'en', personName: '');
    expect(anonymous.last.description, startsWith('This person has already lived'));
  });

  test('astronomical seasons, named for both hemispheres', () {
    expect(northernSeason(DateTime(2000, 3, 19)), 3); // encore l'hiver
    expect(northernSeason(DateTime(2000, 3, 20)), 0);
    expect(northernSeason(DateTime(2000, 6, 21)), 1);
    expect(northernSeason(DateTime(2000, 9, 21)), 1);
    expect(northernSeason(DateTime(2000, 9, 22)), 2);
    expect(northernSeason(DateTime(2000, 12, 20)), 2); // encore l'automne
    expect(northernSeason(DateTime(2000, 12, 21)), 3);
    final fr = birthInsights(DateTime(1995, 1, 10), now, 'fr');
    final season = fr.firstWhere((i) => i.title == 'Saison de naissance');
    expect(season.description,
        "Une naissance en hiver dans l'hémisphère nord, et en été dans "
        "l'hémisphère sud.");
  });

  test('moon phase matches known new and full moons', () {
    // Nouvelle lune du 23 novembre 2003 (éclipse totale de Soleil).
    final newMoon = moonAge(DateTime.utc(2003, 11, 23, 23));
    expect(moonPhaseIndex(newMoon), 0);
    expect(moonIllumination(newMoon), lessThan(0.02));
    // Pleine lune du 23 avril 2024.
    final fullMoon = moonAge(DateTime.utc(2024, 4, 24));
    expect(moonPhaseIndex(fullMoon), 4);
    expect(moonIllumination(fullMoon), greaterThan(0.98));
    // Premier quartier du 12 août 2024 : moitié éclairée.
    final quarter = moonAge(DateTime.utc(2024, 8, 12, 15, 19));
    expect(moonPhaseIndex(quarter), 2);
    expect(moonIllumination(quarter), closeTo(0.5, 0.05));
  });

  test('generations follow the Pew Research Center boundaries', () {
    expect(generationIndex(2013), 0);
    expect(generationIndex(2012), 1);
    expect(generationIndex(2003), 1);
    expect(generationIndex(1997), 1);
    expect(generationIndex(1996), 2);
    expect(generationIndex(1981), 2);
    expect(generationIndex(1980), 3);
    expect(generationIndex(1964), 4);
    expect(generationIndex(1945), 5);
    final fr = birthInsights(DateTime(2003, 11, 22), now, 'fr');
    expect(fr.firstWhere((i) => i.title == 'Génération').description,
        'Vous faites partie de la génération Z, née entre 1997 et 2012.');
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
