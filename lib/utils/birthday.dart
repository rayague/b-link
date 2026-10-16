/// Calculs de dates d'anniversaire, partagés par l'accueil, les listes et les
/// rappels. Fonctions pures : `now` est toujours passé en paramètre.
library;

/// Année enregistrée quand l'année de naissance est inconnue (anniversaire
/// importé du carnet sans année). Bissextile, pour accepter le 29 février.
const int unknownBirthYear = 4;

/// false si l'année de naissance est inconnue (voir [unknownBirthYear]).
bool hasBirthYear(DateTime birthDate) => birthDate.year != unknownBirthYear;

bool _isLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

/// Date de l'anniversaire en [year]. Un 29 février est fêté le 28 février
/// les années non bissextiles (au lieu de glisser au 1er mars).
DateTime birthdayInYear(DateTime birthDate, int year) {
  if (birthDate.month == 2 && birthDate.day == 29 && !_isLeapYear(year)) {
    return DateTime(year, 2, 28);
  }
  return DateTime(year, birthDate.month, birthDate.day);
}

/// Prochain anniversaire à partir de [now] (aujourd'hui inclus), à minuit.
/// Gère le passage d'année : le 30 décembre, un anniversaire au 2 janvier
/// est dans 3 jours.
DateTime nextBirthday(DateTime birthDate, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final thisYear = birthdayInYear(birthDate, now.year);
  return thisYear.isBefore(today)
      ? birthdayInYear(birthDate, now.year + 1)
      : thisYear;
}

/// Nombre de jours jusqu'au prochain anniversaire (0 = aujourd'hui).
int daysUntilBirthday(DateTime birthDate, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  // Différence en jours calendaires (UTC pour ignorer les changements d'heure).
  final next = nextBirthday(birthDate, now);
  return DateTime.utc(next.year, next.month, next.day)
      .difference(DateTime.utc(today.year, today.month, today.day))
      .inDays;
}

/// Date d'un contact (ISO 8601) ou `null` si invalide.
DateTime? parseBirthDate(String iso) =>
    iso.isEmpty ? null : DateTime.tryParse(iso);
