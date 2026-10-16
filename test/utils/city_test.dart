import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/models/user_profile.dart';
import 'package:b_link/services/directory_service.dart';
import 'package:b_link/utils/city.dart';

void main() {
  test('city names are normalised (case, accents, hyphens, spaces)', () {
    for (final variant in ['Saint-Étienne', 'saint  etienne ', 'SAINT ETIENNE']) {
      expect(normalizeCity(variant), 'saint etienne');
    }
    expect(normalizeCity("L'Haÿ-les-Roses"), 'l hay les roses');
  });

  test('the key includes the country (Paris FR is not Paris US)', () {
    expect(cityKey('FR', 'Paris'), 'FR:paris');
    expect(cityKey('US', 'Paris'), 'US:paris');
    expect(cityKey(null, 'Paris'), isNull);
    expect(cityKey('FR', '  '), isNull);
  });

  test('the city key is published only when the current city is shared', () {
    final p = UserProfile(
        uid: 'u', name: 'A', birthDate: DateTime(1990, 10, 15),
        countryCode: 'CI', birthCity: 'Abidjan', isPublic: true);
    expect(p.toPublicJson().containsKey('cityKey'), isFalse);
    p.publicBirthCity = true;
    expect(p.toPublicJson()['cityKey'], 'CI:abidjan');
  });

  test('directory query by city', () async {
    final db = FakeFirebaseFirestore();
    Future<void> add(String uid, String? key) =>
        db.collection('public_profiles').doc(uid).set({
          'uid': uid, 'birthDayKey': '10-15', 'isPublic': true,
          if (key != null) 'cityKey': key,
        });
    await add('abidjan', 'CI:abidjan');
    await add('paris-fr', 'FR:paris');
    await add('paris-us', 'US:paris');
    await add('no-city', null);

    final snap = await DirectoryService(firestore: db)
        .query(DateTime(1990, 10, 15), DirectoryPeriod.day, cityKey: 'FR:paris')
        .get();
    expect(snap.docs.map((d) => d.id), ['paris-fr']);
  });
}
