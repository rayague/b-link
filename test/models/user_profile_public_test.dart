import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/models/user_profile.dart';

UserProfile _profile({
  DateTime? birthDate,
  bool isPublic = true,
  bool publicName = false,
  bool publicBirthDate = false,
  bool publicSocials = false,
}) =>
    UserProfile(
      uid: 'u1',
      name: 'Alice Martin',
      birthDate: birthDate ?? DateTime(1990, 10, 14),
      birthTime: '08:30',
      birthplace: 'Lyon',
      socialLinks: {'instagram': 'https://instagram.com/alice'},
      isPublic: isPublic,
      publicName: publicName,
      publicBirthDate: publicBirthDate,
      publicSocials: publicSocials,
    );

void main() {
  group('toPublicJson', () {
    test('never contains private fields that were not opted in', () {
      final json = _profile().toPublicJson();

      expect(json['birthDayKey'], '10-14');
      for (final key in [
        'name', 'birthDate', 'birthTime', 'birthplace', 'socialLinks',
        'email', 'bio', 'givenName', 'familyName',
      ]) {
        expect(json.containsKey(key), isFalse, reason: key);
      }
    });

    test('includes exactly the opted-in fields', () {
      final json = _profile(publicName: true, publicSocials: true)
          .toPublicJson();

      expect(json['name'], 'Alice Martin');
      expect(json['socialLinks'], {'instagram': 'https://instagram.com/alice'});
      expect(json.containsKey('birthDate'), isFalse);
    });

    test('country is shared only when opted in and well-formed', () {
      final p = _profile()..countryCode = 'FR';
      expect(p.toPublicJson().containsKey('countryCode'), isFalse);

      p.publicCountry = true;
      expect(p.toPublicJson()['countryCode'], 'FR');

      // Un code invalide ferait refuser tout le batch par les règles.
      p.countryCode = 'France';
      expect(p.toPublicJson().containsKey('countryCode'), isFalse);
    });

    test('region follows the shown country (continent filter)', () {
      final p = _profile()..countryCode = 'BJ';
      expect(p.toPublicJson().containsKey('region'), isFalse);
      p.publicCountry = true;
      expect(p.toPublicJson()['region'], 'AF');
      p.countryCode = 'FR';
      expect(p.toPublicJson()['region'], 'EU');
      p.countryCode = 'BR';
      expect(p.toPublicJson()['region'], 'SA');
      p.countryCode = 'AQ'; // Antarctique : pas de région
      expect(p.toPublicJson().containsKey('region'), isFalse);
    });

    test('birth time is only shared together with the birth date', () {
      final p = _profile()..publicBirthTime = true;
      expect(p.toPublicJson().containsKey('birthTime'), isFalse);
    });

    test('keys stay within the Firestore rules allow-list', () {
      const allowed = {
        'uid', 'name', 'birthDayKey', 'birthDate', 'birthTime', 'birthplace',
        'birthCountry', 'birthCity', 'zodiac', 'socialLinks', 'isPublic',
        'publicName', 'publicBirthDate', 'publicBirthTime', 'publicBirthPlace',
        'publicBirthCountry', 'publicBirthCity', 'publicSocials',
        'publicZodiac', 'updatedAt', 'countryCode', 'publicCountry',
        'publicPhoto', 'cityKey', 'region',
      };
      final p = _profile(
          publicName: true, publicBirthDate: true, publicSocials: true)
        ..publicBirthTime = true
        ..publicBirthPlace = true
        ..publicBirthCountry = true
        ..publicBirthCity = true
        ..publicZodiac = true
        ..birthCountry = 'France'
        ..birthCity = 'Paris'
        ..zodiac = 'Balance'
        ..countryCode = 'FR'
        ..publicCountry = true;
      expect(allowed.containsAll(p.toPublicJson().keys), isTrue);
    });
  });

  group('minimum age', () {
    test('ageOn handles the birthday boundary', () {
      final birth = DateTime(2010, 10, 15);
      expect(UserProfile.ageOn(birth, DateTime(2026, 10, 14)), 15);
      expect(UserProfile.ageOn(birth, DateTime(2026, 10, 15)), 16);
    });

    test('a minor is never published even if marked public', () {
      final now = DateTime.now();
      final minor = _profile(birthDate: DateTime(now.year - 12, 1, 1));
      expect(minor.shouldBePublished, isFalse);
      expect(_profile().shouldBePublished, isTrue);
      expect(_profile(isPublic: false).shouldBePublished, isFalse);
    });
  });

  test('the photo is published only if it exists and is opted in', () {
    final p = _profile()..publicPhoto = true;
    expect(p.toPublicJson()['publicPhoto'], isFalse); // pas de photo
    p.hasPhoto = true;
    expect(p.toPublicJson()['publicPhoto'], isTrue);
    p.publicPhoto = false;
    expect(p.toPublicJson()['publicPhoto'], isFalse);
    // Jamais d'URL ni de chemin de fichier dans la projection publique.
    expect(p.toPublicJson().keys.any((k) => k.toLowerCase().contains('url')), isFalse);
  });

  test('a public projection without birthDate can still be read', () {
    final p = UserProfile.fromMap({
      'uid': 'u2',
      'birthDayKey': '02-29',
      'isPublic': true,
    });
    expect(p.birthDate.month, 2);
    expect(p.birthDate.day, 29);
    expect(p.publicBirthDate, isFalse);
  });
}
