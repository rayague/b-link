import 'package:flutter/material.dart';

class BirthInsightsWidget extends StatelessWidget {
  final DateTime birthDate;
  final String? birthTime;
  final String? birthPlace;
  final String? birthCountry;

  const BirthInsightsWidget({
    super.key,
    required this.birthDate,
    this.birthTime,
    this.birthPlace,
    this.birthCountry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insights = _generateInsights();

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
          color: const Color(0xFFFBBF24).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.1),
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
                      'Le saviez-vous ?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF78350F),
                      ),
                    ),
                    Text(
                      'Découvrez votre jour de naissance',
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

  Widget _buildInsightCard(Map<String, dynamic> insight, bool isDark) {
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
              color: (insight['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              insight['icon'] as IconData,
              color: insight['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['description'] as String,
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

  List<Map<String, dynamic>> _generateInsights() {
    final insights = <Map<String, dynamic>>[];

    // Day of week
    final dayOfWeek = _getDayOfWeek(birthDate.weekday);
    insights.add({
      'icon': Icons.calendar_today_rounded,
      'color': const Color(0xFF3B82F6),
      'title': 'Jour de la semaine',
      'description':
          'Vous êtes né(e) un ${dayOfWeek.toLowerCase()}. ${_getDayCharacteristic(birthDate.weekday)}',
    });

    // Season
    final season = _getSeason(birthDate.month);
    insights.add({
      'icon': _getSeasonIcon(birthDate.month),
      'color': _getSeasonColor(birthDate.month),
      'title': 'Saison de naissance',
      'description':
          'Vous êtes un enfant de l\'$season. ${_getSeasonCharacteristic(birthDate.month)}',
    });

    // Moon phase (approximation)
    final moonPhase = _getMoonPhase(birthDate);
    insights.add({
      'icon': Icons.nightlight_round,
      'color': const Color(0xFF8B5CF6),
      'title': 'Phase lunaire',
      'description': moonPhase,
    });

    // Historical context
    final yearInsight = _getYearInsight(birthDate.year);
    insights.add({
      'icon': Icons.history_edu_rounded,
      'color': const Color(0xFFEC4899),
      'title': 'Contexte historique',
      'description': yearInsight,
    });

    // Age in days
    final ageInDays = DateTime.now().difference(birthDate).inDays;
    insights.add({
      'icon': Icons.timer_outlined,
      'color': const Color(0xFF10B981),
      'title': 'Votre vie en chiffres',
      'description':
          'Vous avez vécu ${_formatNumber(ageInDays)} jours, soit environ ${_formatNumber((ageInDays * 24).toInt())} heures !',
    });

    // Weather characteristic (fun fact based on season and month)
    insights.add({
      'icon': Icons.wb_sunny_outlined,
      'color': const Color(0xFFF59E0B),
      'title': 'Météo probable',
      'description':
          _getWeatherInsight(birthDate.month, birthPlace, birthCountry),
    });

    return insights;
  }

  String _getDayOfWeek(int weekday) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    return days[weekday - 1];
  }

  String _getDayCharacteristic(int weekday) {
    const characteristics = [
      'Les personnes nées le lundi sont souvent intuitives et émotionnelles.',
      'Les natifs du mardi sont énergiques et courageux.',
      'Ceux nés le mercredi sont communicatifs et adaptables.',
      'Les jeudis sont associés à la chance et l\'expansion.',
      'Le vendredi apporte créativité et harmonie.',
      'Les samedis donnent discipline et sagesse.',
      'Le dimanche confère leadership et vitalité.',
    ];
    return characteristics[weekday - 1];
  }

  String _getSeason(int month) {
    if (month >= 3 && month <= 5) return 'printemps';
    if (month >= 6 && month <= 8) return 'été';
    if (month >= 9 && month <= 11) return 'automne';
    return 'hiver';
  }

  IconData _getSeasonIcon(int month) {
    if (month >= 3 && month <= 5) return Icons.local_florist_rounded;
    if (month >= 6 && month <= 8) return Icons.wb_sunny_rounded;
    if (month >= 9 && month <= 11) return Icons.spa_rounded;
    return Icons.ac_unit_rounded;
  }

  Color _getSeasonColor(int month) {
    if (month >= 3 && month <= 5) return const Color(0xFFEC4899);
    if (month >= 6 && month <= 8) return const Color(0xFFF59E0B);
    if (month >= 9 && month <= 11) return const Color(0xFF8B5CF6);
    return const Color(0xFF3B82F6);
  }

  String _getSeasonCharacteristic(int month) {
    if (month >= 3 && month <= 5) {
      return 'Les enfants du printemps sont souvent optimistes et pleins de vie.';
    }
    if (month >= 6 && month <= 8) {
      return 'Les natifs de l\'été rayonnent d\'énergie et de chaleur humaine.';
    }
    if (month >= 9 && month <= 11) {
      return 'Les âmes d\'automne sont contemplatives et créatives.';
    }
    return 'Les enfants de l\'hiver sont résilients et sages.';
  }

  String _getMoonPhase(DateTime date) {
    // Simplified moon phase calculation (approximation)
    const lunarMonth = 29.53059;
    final knownNewMoon = DateTime(2000, 1, 6, 18, 14);
    final daysSinceNewMoon = date.difference(knownNewMoon).inDays;
    final phase = (daysSinceNewMoon % lunarMonth) / lunarMonth;

    if (phase < 0.0625 || phase >= 0.9375) {
      return 'Vous êtes né(e) lors d\'une Nouvelle Lune 🌑, symbole de nouveaux départs.';
    } else if (phase < 0.1875) {
      return 'Votre naissance a eu lieu durant le Premier Croissant 🌒, période de croissance.';
    } else if (phase < 0.3125) {
      return 'Né(e) sous le Premier Quartier 🌓, symbole d\'action et de décision.';
    } else if (phase < 0.4375) {
      return 'La Lune Gibbeuse Croissante 🌔 éclairait votre naissance, signe de perfectionnement.';
    } else if (phase < 0.5625) {
      return 'Vous êtes né(e) lors d\'une Pleine Lune 🌕, moment de plénitude et de révélation.';
    } else if (phase < 0.6875) {
      return 'La Lune Gibbeuse Décroissante 🌖 marquait votre naissance, temps de partage.';
    } else if (phase < 0.8125) {
      return 'Né(e) sous le Dernier Quartier 🌗, période de libération et de transformation.';
    } else {
      return 'Le Dernier Croissant 🌘 accompagnait votre naissance, symbole de sagesse.';
    }
  }

  String _getYearInsight(int year) {
    if (year >= 2010) {
      return 'Vous faites partie de la Génération Alpha, les premiers vrais natifs du numérique !';
    } else if (year >= 1997) {
      return 'Vous êtes de la Génération Z, créatifs et technophiles.';
    } else if (year >= 1981) {
      return 'Vous êtes un Millennial, témoin de la révolution digitale.';
    } else if (year >= 1965) {
      return 'Vous appartenez à la Génération X, indépendants et pragmatiques.';
    } else if (year >= 1946) {
      return 'Vous êtes un Baby Boomer, porteur d\'idéaux et de changements.';
    } else {
      return 'Vous appartenez à la Génération Silencieuse, gardienne de sagesse.';
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  String _getWeatherInsight(int month, String? place, String? country) {
    final location = place != null && country != null
        ? 'à $place, $country'
        : place != null
            ? 'à $place'
            : country != null
                ? 'en $country'
                : '';

    if (month == 12 || month == 1 || month == 2) {
      return 'En hiver $location, il faisait probablement froid. Peut-être neigeait-il ? ❄️';
    } else if (month >= 3 && month <= 5) {
      return 'Le printemps $location apportait sûrement douceur et fleurs. Les oiseaux chantaient ! 🌸';
    } else if (month >= 6 && month <= 8) {
      return 'L\'été $location était chaud et ensoleillé. Les vacances d\'été battaient leur plein ! ☀️';
    } else {
      return 'L\'automne $location peignait les arbres de couleurs chaudes. La rentrée approchait ! 🍂';
    }
  }
}
