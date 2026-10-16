import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// "Le saviez-vous ?" : petites anecdotes sur une date de naissance.
///
/// Sur son propre profil, le texte s'adresse à l'utilisateur ("vous") ; sur
/// le profil public d'une autre personne ([personName] non nul), il parle de
/// cette personne. Les anecdotes restent factuelles : pas de "météo probable"
/// (l'app est mondiale), et les saisons précisent l'hémisphère.
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = AppLocalizations.of(context).locale.languageCode == 'fr'
        ? 'fr'
        : 'en';
    final insights = birthInsights(birthDate, DateTime.now(), lang,
        personName: personName);
    final header = _header[lang]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF374151), const Color(0xFF1F2937)]
              : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFFCD34D)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      header.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF78350F),
                      ),
                    ),
                    Text(
                      header.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.grey[400] : const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...insights.map((insight) => _buildInsightCard(insight, isDark)),
        ],
      ),
    );
  }

  static const _header = {
    'fr': (title: 'Le saviez-vous ?', subtitle: 'Petites histoires autour d\'une date de naissance'),
    'en': (title: 'Did you know?', subtitle: 'Little stories about a birth date'),
  };

  Widget _buildInsightCard(BirthInsight insight, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFFED7AA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(insight.icon, color: insight.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une anecdote affichée dans l'encart.
class BirthInsight {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const BirthInsight(this.icon, this.color, this.title, this.description);
}

/// Anecdotes pour [birthDate] (fonction pure, testable).
///
/// [personName] null : on s'adresse à l'utilisateur. Non nul : on parle d'une
/// autre personne (son nom si non vide, sinon "cette personne").
List<BirthInsight> birthInsights(DateTime birthDate, DateTime now, String lang,
    {String? personName}) {
  final fr = lang == 'fr';
  final self = personName == null;
  final who = self
      ? null
      : (personName.trim().isNotEmpty
          ? personName.trim()
          : (fr ? 'Cette personne' : 'This person'));

  final weekday = birthDate.weekday - 1; // 0 = lundi
  final days = fr
      ? const ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche']
      : const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final dayTraits = fr
      ? const [
          'La tradition associe le lundi à l\'intuition et à la sensibilité.',
          'La tradition associe le mardi à l\'énergie et au courage.',
          'La tradition associe le mercredi à la communication et à l\'adaptabilité.',
          'La tradition associe le jeudi à la chance et à l\'ouverture.',
          'La tradition associe le vendredi à la créativité et à l\'harmonie.',
          'La tradition associe le samedi à la discipline et à la sagesse.',
          'La tradition associe le dimanche au rayonnement et à la vitalité.',
        ]
      : const [
          'Tradition links Monday with intuition and sensitivity.',
          'Tradition links Tuesday with energy and courage.',
          'Tradition links Wednesday with communication and adaptability.',
          'Tradition links Thursday with luck and open-mindedness.',
          'Tradition links Friday with creativity and harmony.',
          'Tradition links Saturday with discipline and wisdom.',
          'Tradition links Sunday with radiance and vitality.',
        ];
  final dayLine = self
      ? (fr
          ? 'Vous avez vu le jour un ${days[weekday]}.'
          : 'You were born on a ${days[weekday]}.')
      : (fr
          ? '$who a vu le jour un ${days[weekday]}.'
          : '$who was born on a ${days[weekday]}.');

  // Saison astronomique de l'hémisphère nord (précisé : l'app est mondiale).
  final m = birthDate.month;
  final season = m >= 3 && m <= 5
      ? 0
      : m >= 6 && m <= 8
          ? 1
          : m >= 9 && m <= 11
              ? 2
              : 3;
  final seasonNames = fr
      ? const ['au printemps', 'en été', 'en automne', 'en hiver']
      : const ['in spring', 'in summer', 'in autumn', 'in winter'];
  final seasonSouth = fr
      ? const ['l\'automne', 'l\'hiver', 'le printemps', 'l\'été']
      : const ['autumn', 'winter', 'spring', 'summer'];
  final seasonIcons = const [
    Icons.local_florist_rounded,
    Icons.wb_sunny_rounded,
    Icons.spa_rounded,
    Icons.ac_unit_rounded,
  ];
  final seasonColors = const [
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
  ];
  final seasonLine = fr
      ? 'Une naissance ${seasonNames[season]} dans l\'hémisphère nord, '
          'et ${seasonSouth[season]} dans l\'hémisphère sud.'
      : 'A birthday ${seasonNames[season]} in the Northern Hemisphere, '
          'and in ${seasonSouth[season]} in the Southern Hemisphere.';

  // Phase lunaire (approximation à partir d'une nouvelle lune de référence).
  const lunarMonth = 29.53059;
  final knownNewMoon = DateTime(2000, 1, 6, 18, 14);
  final phase =
      ((birthDate.difference(knownNewMoon).inHours / 24) % lunarMonth) /
          lunarMonth;
  final phaseIndex = ((phase * 8) + 0.5).floor() % 8;
  final moons = fr
      ? const [
          'une Nouvelle Lune 🌑, symbole de nouveaux départs',
          'un Premier Croissant 🌒, période de croissance',
          'un Premier Quartier 🌓, symbole d\'action',
          'une Lune Gibbeuse Croissante 🌔, signe d\'élan',
          'une Pleine Lune 🌕, moment de plénitude',
          'une Lune Gibbeuse Décroissante 🌖, temps du partage',
          'un Dernier Quartier 🌗, période de transformation',
          'un Dernier Croissant 🌘, symbole de sagesse',
        ]
      : const [
          'a New Moon 🌑, a symbol of new beginnings',
          'a Waxing Crescent 🌒, a time of growth',
          'a First Quarter moon 🌓, a symbol of action',
          'a Waxing Gibbous moon 🌔, a sign of momentum',
          'a Full Moon 🌕, a moment of fullness',
          'a Waning Gibbous moon 🌖, a time for sharing',
          'a Last Quarter moon 🌗, a time of transformation',
          'a Waning Crescent 🌘, a symbol of wisdom',
        ];
  final moonLine = fr
      ? 'Le ciel de cette nuit-là montrait ${moons[phaseIndex]}.'
      : 'The sky that night showed ${moons[phaseIndex]}.';

  final y = birthDate.year;
  final generation = fr
      ? (y >= 2010
          ? 'la Génération Alpha, les premiers vrais natifs du numérique'
          : y >= 1997
              ? 'la Génération Z, créative et connectée'
              : y >= 1981
                  ? 'la génération des Millennials, témoin de la révolution numérique'
                  : y >= 1965
                      ? 'la Génération X, indépendante et pragmatique'
                      : y >= 1946
                          ? 'la génération du Baby-boom, porteuse d\'idéaux et de changements'
                          : 'la Génération silencieuse, gardienne de la mémoire')
      : (y >= 2010
          ? 'Generation Alpha, the first true digital natives'
          : y >= 1997
              ? 'Generation Z, creative and connected'
              : y >= 1981
                  ? 'the Millennials, who witnessed the digital revolution'
                  : y >= 1965
                      ? 'Generation X, independent and pragmatic'
                      : y >= 1946
                          ? 'the Baby Boomers, carriers of ideals and change'
                          : 'the Silent Generation, keepers of memory');
  final generationLine = self
      ? (fr ? 'Vous faites partie de $generation.' : 'You belong to $generation.')
      : (fr ? '$who fait partie de $generation.' : '$who belongs to $generation.');

  final ageInDays = now.difference(birthDate).inDays;
  String fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}${fr ? ' ' : ','}');
  final lifeLine = self
      ? (fr
          ? 'Vous avez déjà vécu ${fmt(ageInDays)} jours, soit environ ${fmt(ageInDays * 24)} heures !'
          : 'You have already lived ${fmt(ageInDays)} days, or about ${fmt(ageInDays * 24)} hours!')
      : (fr
          ? '$who a déjà vécu ${fmt(ageInDays)} jours, soit environ ${fmt(ageInDays * 24)} heures !'
          : '$who has already lived ${fmt(ageInDays)} days, or about ${fmt(ageInDays * 24)} hours!');

  return [
    BirthInsight(Icons.calendar_today_rounded, const Color(0xFF3B82F6),
        fr ? 'Jour de la semaine' : 'Day of the week',
        '$dayLine ${dayTraits[weekday]}'),
    BirthInsight(seasonIcons[season], seasonColors[season],
        fr ? 'Saison de naissance' : 'Birth season', seasonLine),
    BirthInsight(Icons.nightlight_round, const Color(0xFF8B5CF6),
        fr ? 'Phase lunaire' : 'Moon phase', moonLine),
    BirthInsight(Icons.history_edu_rounded, const Color(0xFFEC4899),
        fr ? 'Génération' : 'Generation', generationLine),
    BirthInsight(Icons.timer_outlined, const Color(0xFF10B981),
        fr ? 'Une vie en chiffres' : 'A life in numbers', lifeLine),
  ];
}
