import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'birthday.dart';

/// Libellés d'anniversaire partagés par les écrans.

/// « Aujourd'hui », « Demain », « Dans 12 j ».
String countdownLabel(AppLocalizations l10n, int days) {
  if (days == 0) return l10n.translate('todayShort');
  if (days == 1) return l10n.translate('tomorrow');
  return l10n.translate('inDaysCompact').replaceAll('{count}', '$days');
}

/// « 14 mars » / « March 14 ».
String dayMonthLabel(AppLocalizations l10n, DateTime date) =>
    DateFormat.MMMMd(l10n.locale.languageCode).format(date);

/// « 14 mars 1990 » / « March 14, 1990 ».
String fullDateLabel(AppLocalizations l10n, DateTime date) =>
    DateFormat.yMMMMd(l10n.locale.languageCode).format(date);

/// Âge atteint au prochain anniversaire (null si la date est dans le futur
/// ou si l'année est inconnue).
int? ageAtNextBirthday(DateTime birth, DateTime now) {
  final next = nextBirthday(birth, now);
  final age = next.year - birth.year;
  return age > 0 && age < 130 ? age : null;
}
