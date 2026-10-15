import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

/// Période de recherche des "jumeaux d'anniversaire".
enum DirectoryPeriod { day, week, month }

/// Requêtes sur l'annuaire `public_profiles`.
///
/// Tout repose sur `birthDayKey` (MM-DD) : égalité pour le jour, `whereIn`
/// pour la semaine, plage de chaînes pour le mois. Le filtre pays ajoute une
/// égalité sur `countryCode` (index composite dans firestore.indexes.json
/// pour le cas du mois).
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

  Query<Map<String, dynamic>> query(
    DateTime birthDate,
    DirectoryPeriod period, {
    String? countryCode,
  }) {
    Query<Map<String, dynamic>> q = _db.collection('public_profiles');
    if (countryCode != null) {
      q = q.where('countryCode', isEqualTo: countryCode);
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
