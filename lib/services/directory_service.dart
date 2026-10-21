import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

/// Période de recherche des "jumeaux d'anniversaire".
enum DirectoryPeriod { day, week, month }

/// Requêtes sur l'annuaire `public_profiles`.
///
/// Tout repose sur `birthDayKey` (MM-DD) : égalité pour le jour, `whereIn`
/// pour la semaine, plage de chaînes pour le mois. Les filtres pays, région
/// et ville ajoutent une égalité (index composites dans
/// firestore.indexes.json pour le cas du mois).
class DirectoryService {
  /// Doit rester <= à la limite imposée par firestore.rules.
  static const int pageSize = 50;

  final FirebaseFirestore? _firestore;
  DirectoryService({FirebaseFirestore? firestore}) : _firestore = firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Clés MM-DD de birthDate-3 à birthDate+3. Le calcul se fait sur une année
  /// bissextile pour que le 29 février soit voisin du 28 et du 1er mars ; le
  /// passage d'année (fin décembre / début janvier) est géré naturellement.
  static List<String> weekKeys(DateTime birthDate) {
    final center = DateTime(2000, birthDate.month, birthDate.day);
    return [
      for (var offset = -3; offset <= 3; offset++)
        UserProfile.dayKeyOf(
            DateTime(center.year, center.month, center.day + offset)),
    ];
  }

  /// [cityKey] ("PAYS:ville", voir utils/city.dart) restreint à une ville ;
  /// sinon [countryCode] restreint à un pays ; sinon [region] (voir
  /// utils/regions.dart) à un continent ; sinon le monde entier.
  Query<Map<String, dynamic>> query(
    DateTime birthDate,
    DirectoryPeriod period, {
    String? countryCode,
    String? cityKey,
    String? region,
  }) {
    Query<Map<String, dynamic>> q = _db.collection('public_profiles');
    if (cityKey != null) {
      q = q.where('cityKey', isEqualTo: cityKey);
    } else if (countryCode != null) {
      q = q.where('countryCode', isEqualTo: countryCode);
    } else if (region != null) {
      q = q.where('region', isEqualTo: region);
    }
    switch (period) {
      case DirectoryPeriod.day:
        q = q.where('birthDayKey', isEqualTo: UserProfile.dayKeyOf(birthDate));
      case DirectoryPeriod.week:
        q = q.where('birthDayKey', whereIn: weekKeys(birthDate));
      case DirectoryPeriod.month:
        final month = birthDate.month.toString().padLeft(2, '0');
        q = q
            .where('birthDayKey', isGreaterThanOrEqualTo: '$month-01')
            .where('birthDayKey', isLessThanOrEqualTo: '$month-31')
            .orderBy('birthDayKey');
    }
    return q.limit(pageSize);
  }
}
