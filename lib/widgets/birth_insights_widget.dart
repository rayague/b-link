import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'ui/components.dart';
import 'ui/glass.dart';

/// « Le saviez-vous ? » : des faits vérifiables sur une date de naissance.
///
/// Sur son propre profil, le texte s'adresse à l'utilisateur (« vous ») ;
/// sur le profil public d'une autre personne ([personName] non nul), il parle
/// de cette personne. Rien d'inventé : origine du nom du jour, saison
/// astronomique (les deux hémisphères : l'app est mondiale), phase de la
/// Lune calculée, génération selon le Pew Research Center, jours vécus.
class BirthInsightsWidget extends StatelessWidget {
  final DateTime birthDate;
  final String? birthTime;
  final String? birthPlace;
  final String? birthCountry;

  /// Prénom/nom de la personne si ce n'est pas l'utilisateur lui-même
  /// ("" = autre personne dont le nom n'est pas public).
  final String? personName;

  const BirthInsightsWidget({
    super.key,
    required this.birthDate,
    this.birthTime,
    this.birthPlace,
    this.birthCountry,
    this.personName,
  });

  static const _header = {
    'fr': (title: 'Le saviez-vous ?', subtitle: 'Des faits sur cette date de naissance'),
    'en': (title: 'Did you know?', subtitle: 'Facts about this birth date'),
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lang = AppLocalizations.of(context).locale.languageCode == 'fr'
        ? 'fr'
        : 'en';
    final insights = birthInsights(birthDate, DateTime.now(), lang,
        personName: personName, birthTime: birthTime);
    final header = _header[lang]!;

    return GlassCard(
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.auto_awesome_outlined, tone: Tone.accent),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(header.title, style: t.titleMedium),
                    Text(header.subtitle, style: t.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          for (final insight in insights) ...[
            const SizedBox(height: Space.m),
            const Divider(),
            const SizedBox(height: Space.m),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(insight.icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insight.title, style: t.titleSmall),
                      const SizedBox(height: 2),
                      Text(insight.description,
                          style: t.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Une anecdote affichée dans l'encart.
class BirthInsight {
  final IconData icon;
  final String title;
  final String description;
  const BirthInsight(this.icon, this.title, this.description);
}

/// Saison astronomique de l'hémisphère nord (0 printemps, 1 été,
/// 2 automne, 3 hiver). Équinoxes et solstices aux dates les plus
/// fréquentes (20 mars, 21 juin, 22 septembre, 21 décembre) : selon
/// l'année, la date réelle peut varier d'un jour.
int northernSeason(DateTime d) {
  final md = d.month * 100 + d.day;
  if (md >= 320 && md < 621) return 0;
  if (md >= 621 && md < 922) return 1;
  if (md >= 922 && md < 1221) return 2;
  return 3;
}

/// Âge de la Lune (jours depuis la nouvelle lune) au moment donné, en UTC.
/// Lunaison moyenne : l'erreur reste inférieure à un jour, assez pour
/// nommer la phase.
double moonAge(DateTime utc) {
  const synodic = 29.530588853;
  final reference = DateTime.utc(2000, 1, 6, 18, 14); // nouvelle lune
  final days = utc.difference(reference).inMinutes / 1440;
  final age = days % synodic;
  return age < 0 ? age + synodic : age;
}

/// Part du disque éclairée (0 à 1) pour un âge de la Lune donné.
double moonIllumination(double age) =>
    (1 - math.cos(2 * math.pi * age / 29.530588853)) / 2;

/// Phase (0 nouvelle lune … 7 dernier croissant) pour un âge donné.
int moonPhaseIndex(double age) =>
    ((age / 29.530588853) * 8 + 0.5).floor() % 8;

/// Génération selon les bornes du Pew Research Center (Alpha : à partir de
/// 2013, après la génération Z).
int generationIndex(int year) {
  if (year >= 2013) return 0; // Alpha
  if (year >= 1997) return 1; // Z
  if (year >= 1981) return 2; // Millennials
  if (year >= 1965) return 3; // X
  if (year >= 1946) return 4; // Baby-boom
  if (year >= 1928) return 5; // Silencieuse
  return 6; // Grande génération
}

/// Anecdotes pour [birthDate] (fonction pure, testable).
///
/// [personName] null : on s'adresse à l'utilisateur. Non nul : on parle d'une
/// autre personne (son nom si non vide, sinon « cette personne »).
/// [birthTime] (« HH:mm », heure locale) affine la phase de la Lune.
List<BirthInsight> birthInsights(DateTime birthDate, DateTime now, String lang,
    {String? personName, String? birthTime}) {
  final fr = lang == 'fr';
  final self = personName == null;
  final who = self
      ? null
      : (personName.trim().isNotEmpty
          ? personName.trim()
          : (fr ? 'Cette personne' : 'This person'));

  // Jour de la semaine et origine de son nom.
  final weekday = birthDate.weekday - 1; // 0 = lundi
  final days = fr
      ? const ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche']
      : const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final dayOrigins = fr
      ? const [
          'Son nom vient du latin lunae dies, « le jour de la Lune ».',
          'Son nom vient du latin Martis dies, « le jour de Mars ».',
          'Son nom vient du latin Mercurii dies, « le jour de Mercure ».',
          'Son nom vient du latin Jovis dies, « le jour de Jupiter ».',
          'Son nom vient du latin Veneris dies, « le jour de Vénus ».',
          'Son nom vient du latin sambati dies, « le jour du sabbat ».',
          'Son nom vient du latin dies dominicus, « le jour du Seigneur ».',
        ]
      : const [
          'Its name comes from Old English Mōnandæg, "the Moon\'s day".',
          'Its name honours Tiw (Týr), the Norse and Germanic god of war.',
          'Its name honours Woden (Odin), chief of the Norse gods.',
          'Its name honours Thor, the Norse god of thunder.',
          'Its name honours Frigg, the Norse goddess of marriage.',
          'Its name comes from Latin Saturni dies, "Saturn\'s day".',
          'Its name comes from Old English Sunnandæg, "the Sun\'s day".',
        ];
  final dayLine = self
      ? (fr
          ? 'Vous êtes né(e) un ${days[weekday]}.'
          : 'You were born on a ${days[weekday]}.')
      : (fr
          ? '$who est né(e) un ${days[weekday]}.'
          : '$who was born on a ${days[weekday]}.');

  // Saison astronomique, dans les deux hémisphères.
  final season = northernSeason(birthDate);
  final seasonNorth = fr
      ? const ['au printemps', 'en été', 'en automne', 'en hiver']
      : const ['in spring', 'in summer', 'in autumn', 'in winter'];
  final seasonSouth = fr
      ? const ['en automne', 'en hiver', 'au printemps', 'en été']
      : const ['in autumn', 'in winter', 'in spring', 'in summer'];
  const seasonIcons = [
    Icons.local_florist_rounded,
    Icons.wb_sunny_rounded,
    Icons.spa_rounded,
    Icons.ac_unit_rounded,
  ];
  final seasonLine = fr
      ? 'Une naissance ${seasonNorth[season]} dans l\'hémisphère nord, '
          'et ${seasonSouth[season]} dans l\'hémisphère sud.'
      : 'A birth ${seasonNorth[season]} in the Northern Hemisphere, '
          'and ${seasonSouth[season]} in the Southern Hemisphere.';

  // Phase de la Lune, à l'heure de naissance si elle est connue (sinon
  // midi). L'heure est locale et le fuseau inconnu : à quelques heures près,
  // la phase et le pourcentage ne changent presque pas.
  final parts = birthTime?.split(':');
  final hour = int.tryParse(parts?.first ?? '') ?? 12;
  final minute = parts != null && parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final age = moonAge(DateTime.utc(
      birthDate.year, birthDate.month, birthDate.day, hour.clamp(0, 23), minute.clamp(0, 59)));
  final lit = (moonIllumination(age) * 100).round();
  final phases = fr
      ? const [
          'une nouvelle lune 🌑',
          'un premier croissant 🌒',
          'un premier quartier 🌓',
          'une lune gibbeuse croissante 🌔',
          'une pleine lune 🌕',
          'une lune gibbeuse décroissante 🌖',
          'un dernier quartier 🌗',
          'un dernier croissant 🌘',
        ]
      : const [
          'a new moon 🌑',
          'a waxing crescent 🌒',
          'a first-quarter moon 🌓',
          'a waxing gibbous moon 🌔',
          'a full moon 🌕',
          'a waning gibbous moon 🌖',
          'a last-quarter moon 🌗',
          'a waning crescent 🌘',
        ];
  final phase = phases[moonPhaseIndex(age)];
  final moonLine = fr
      ? 'Ce jour-là, la Lune était $phase, éclairée à $lit %.'
      : 'That day, the Moon was $phase, $lit% illuminated.';

  // Génération (Pew Research Center).
  final gen = generationIndex(birthDate.year);
  final generation = fr
      ? const [
          'la génération Alpha, née à partir de 2013',
          'la génération Z, née entre 1997 et 2012',
          'la génération Y (les Millennials), née entre 1981 et 1996',
          'la génération X, née entre 1965 et 1980',
          'la génération du baby-boom, née entre 1946 et 1964',
          'la génération silencieuse, née entre 1928 et 1945',
          'la « Greatest Generation », née avant 1928',
        ][gen]
      : const [
          'Generation Alpha, born from 2013 on',
          'Generation Z, born between 1997 and 2012',
          'the Millennials, born between 1981 and 1996',
          'Generation X, born between 1965 and 1980',
          'the Baby Boomers, born between 1946 and 1964',
          'the Silent Generation, born between 1928 and 1945',
          'the Greatest Generation, born before 1928',
        ][gen];
  final generationLine = self
      ? (fr ? 'Vous faites partie de $generation.' : 'You belong to $generation.')
      : (fr ? '$who fait partie de $generation.' : '$who belongs to $generation.');

  // Une vie en chiffres (jours calendaires, sans les changements d'heure).
  final ageInDays = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(birthDate.year, birthDate.month, birthDate.day))
      .inDays;
  String fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}${fr ? ' ' : ','}');
  final weeks = ageInDays ~/ 7;
  final lifeLine = self
      ? (fr
          ? 'Vous avez déjà vécu ${fmt(ageInDays)} jours, soit ${fmt(weeks)} semaines.'
          : 'You have already lived ${fmt(ageInDays)} days, or ${fmt(weeks)} weeks.')
      : (fr
          ? '$who a déjà vécu ${fmt(ageInDays)} jours, soit ${fmt(weeks)} semaines.'
          : '$who has already lived ${fmt(ageInDays)} days, or ${fmt(weeks)} weeks.');

  return [
    BirthInsight(Icons.calendar_today_rounded,
        fr ? 'Jour de la semaine' : 'Day of the week', '$dayLine ${dayOrigins[weekday]}'),
    BirthInsight(seasonIcons[season],
        fr ? 'Saison de naissance' : 'Birth season', seasonLine),
    BirthInsight(Icons.nightlight_round, fr ? 'La Lune ce jour-là' : 'The Moon that day',
        moonLine),
    BirthInsight(Icons.history_edu_rounded, fr ? 'Génération' : 'Generation',
        generationLine),
    if (ageInDays > 0)
      BirthInsight(Icons.timer_outlined,
          fr ? 'Une vie en chiffres' : 'A life in numbers', lifeLine),
  ];
}
