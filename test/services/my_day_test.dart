import 'package:b_link/services/constellation_service.dart';
import 'package:b_link/services/famous_births_service.dart';
import 'package:b_link/utils/birthday.dart';
import 'package:b_link/utils/day_facts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('day facts', () {
    test('about 22 million people share an ordinary birthday', () {
      final n = worldTwins(DateTime(1996, 3, 21));
      expect(n, closeTo(22.4e6, 0.1e6));
    });

    test('29 February is four times rarer', () {
      final leap = worldTwins(DateTime(1996, 2, 29));
      expect(leap, closeTo(5.6e6, 0.1e6));
    });

    test('days lived and full moons', () {
      final now = DateTime(2026, 10, 16);
      expect(daysLived(DateTime(2026, 10, 6), now), 10);
      expect(daysLived(DateTime(unknownBirthYear, 3, 21), now), isNull);
      expect(fullMoonsSeen(10000), 338);
    });
  });

  group('famous births', () {
    final feed = {
      'births': [
        {
          'year': 2007,
          'pages': [
            {
              'pageid': 1,
              'titles': {'normalized': 'Ethan Nwaneri'},
              'description': 'footballeur anglais',
            }
          ],
        },
        {
          'year': 1685,
          'pages': [
            {
              'pageid': 2,
              'title': 'Jean-Sébastien_Bach',
              'description': 'compositeur allemand',
              'thumbnail': {'source': 'https://upload/bach.jpg'},
              'content_urls': {
                'mobile': {'page': 'https://fr.m.wikipedia.org/wiki/Bach'}
              },
            }
          ],
        },
        {'year': 1900, 'pages': []},
        {
          'year': 1685,
          'pages': [
            {'pageid': 2, 'title': 'Doublon'}
          ],
        },
      ],
    };

    test('parses one entry per person', () {
      final list = FamousBirthsService.parseFeed(feed);
      expect(list.map((b) => b.name), ['Ethan Nwaneri', 'Jean-Sébastien Bach']);
      expect(list[1].year, 1685);
      expect(list[1].thumbnail, 'https://upload/bach.jpg');
      expect(list[1].url, 'https://fr.m.wikipedia.org/wiki/Bach');
    });

    test('ranks by number of languages', () {
      final counts = FamousBirthsService.parseLanguageCounts({
        'query': {
          'pages': [
            {'pageid': 1, 'langlinkscount': 36},
            {'pageid': 2, 'langlinkscount': 220},
          ]
        }
      });
      final top =
          FamousBirthsService.rank(FamousBirthsService.parseFeed(feed), counts);
      expect(top.first.name, 'Jean-Sébastien Bach');
      expect(top.first.languages, 220);
    });
  });

  group('constellation stats', () {
    final stats = ConstellationStats.fromMap({
      'total': 6,
      'days': {'03-21': 3, '12-25': 2, '01-01': 1},
      'firstNames': [
        {'name': 'Élodie', 'count': 4},
      ],
      'familyNames': 'invalide',
    });

    test('rank and top days', () {
      expect(stats.rankOf('03-21'), 1);
      expect(stats.rankOf('01-01'), 3);
      expect(stats.rankOf('07-14'), 4); // aucun jumeau : après tous les autres
      expect(stats.topDays(2).map((e) => e.key), ['03-21', '12-25']);
    });

    test('name lookup ignores case and accents', () {
      expect(stats.firstNameCount('elodie'), 4);
      expect(stats.firstNameCount('Ray'), isNull);
      expect(stats.familyNames, isEmpty);
    });
  });
}
