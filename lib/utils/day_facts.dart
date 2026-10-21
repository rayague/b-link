import 'birthday.dart';

/// Chiffres autour d'une date de naissance, affichés dans « Mon jour ».
/// Fonctions pures : `now` est toujours passé en paramètre.

/// Population mondiale retenue (ONU, projection 2026 : environ 8,2
/// milliards).
const double worldPopulation = 8.2e9;

/// Durée moyenne d'une lunaison, en jours.
const double synodicMonth = 29.530589;

/// Nombre approximatif de personnes dans le monde nées le même jour de
/// l'année. Hypothèse : naissances réparties uniformément ; le 29 février
/// ne revient qu'une année sur quatre (1 jour sur 1 461).
double worldTwins(DateTime birth) {
  const leapShare = 1 / 1461;
  if (birth.month == 2 && birth.day == 29) return worldPopulation * leapShare;
  return worldPopulation * (1 - leapShare) / 365;
}

/// Jours vécus depuis la naissance (null si l'année est inconnue).
int? daysLived(DateTime birth, DateTime now) {
  if (!hasBirthYear(birth)) return null;
  final d = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(birth.year, birth.month, birth.day))
      .inDays;
  return d < 0 ? null : d;
}

/// Pleines lunes vues depuis la naissance.
int fullMoonsSeen(int days) => days ~/ synodicMonth;
