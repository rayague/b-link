import 'package:flutter/material.dart';

/// Contenu astrologique en français et en anglais.
///
/// L'identifiant d'un signe est son nom français ("Bélier"...), tel que
/// calculé par `Zodiac.computeZodiac` et enregistré dans les profils et
/// l'annuaire : il ne doit pas changer. Seul l'affichage est traduit.
class ZodiacSign {
  final String id;
  final String emoji;
  final String elementId; // fire, earth, air, water
  final List<Color> colors;
  final Map<String, String> name;
  final Map<String, String> planet;
  final Map<String, String> period;
  final Map<String, String> description;
  final Map<String, List<String>> traits;
  final Map<String, List<String>> quotes;

  const ZodiacSign({
    required this.id,
    required this.emoji,
    required this.elementId,
    required this.colors,
    required this.name,
    required this.planet,
    required this.period,
    required this.description,
    required this.traits,
    required this.quotes,
  });
}

class ZodiacContent {
  static const _elements = {
    'fire': {'fr': 'Feu', 'en': 'Fire'},
    'earth': {'fr': 'Terre', 'en': 'Earth'},
    'air': {'fr': 'Air', 'en': 'Air'},
    'water': {'fr': 'Eau', 'en': 'Water'},
  };

  static String _pick(Map<String, String> m, String lang) =>
      m[lang] ?? m['en'] ?? '';
  static List<String> _pickList(Map<String, List<String>> m, String lang) =>
      m[lang] ?? m['en'] ?? const [];

  static ZodiacSign? of(String? id) => id == null ? null : _signs[id];

  static String name(String id, String lang) {
    final s = of(id);
    return s == null ? id : _pick(s.name, lang);
  }

  static String emoji(String id) => of(id)?.emoji ?? '✨';
  static List<Color> colors(String id) =>
      of(id)?.colors ?? const [Color(0xFF8B5CF6), Color(0xFFA78BFA)];
  static String element(String id, String lang) {
    final s = of(id);
    return s == null ? '' : _pick(_elements[s.elementId]!, lang);
  }

  static String planet(String id, String lang) =>
      of(id) == null ? '' : _pick(of(id)!.planet, lang);
  static String period(String id, String lang) =>
      of(id) == null ? '' : _pick(of(id)!.period, lang);
  static String description(String id, String lang) =>
      of(id) == null ? '' : _pick(of(id)!.description, lang);
  static List<String> traits(String id, String lang) =>
      of(id) == null ? const [] : _pickList(of(id)!.traits, lang);
  static List<String> quotes(String id, String lang) =>
      of(id) == null ? const [] : _pickList(of(id)!.quotes, lang);

  static const Map<String, ZodiacSign> _signs = {
    'Bélier': ZodiacSign(
      id: 'Bélier',
      emoji: '♈',
      elementId: 'fire',
      colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
      name: {'fr': 'Bélier', 'en': 'Aries'},
      planet: {'fr': 'Mars ♂', 'en': 'Mars ♂'},
      period: {'fr': '21 mars - 19 avril', 'en': 'March 21 - April 19'},
      description: {
        'fr': "Dynamique, courageux et impulsif. Vous aimez relever les défis et êtes toujours prêt pour l'aventure.",
        'en': 'Dynamic, brave and impulsive. You love a challenge and are always ready for an adventure.',
      },
      traits: {
        'fr': ['Courageux', 'Énergique', 'Déterminé', 'Confiant', 'Passionné', 'Leader'],
        'en': ['Brave', 'Energetic', 'Determined', 'Confident', 'Passionate', 'Leader'],
      },
      quotes: {
        'fr': [
          "Votre énergie naturelle vous pousse à l'action. Canalisez-la vers vos objectifs.",
          'Les leaders ne naissent pas, ils se forgent. Et vous avez cette flamme en vous.',
          "Votre courage inspire les autres. N'ayez pas peur de montrer la voie.",
          "La patience n'est pas l'attente, mais garder une bonne attitude en attendant.",
        ],
        'en': [
          'Your natural energy pushes you into action. Channel it towards your goals.',
          "Leaders aren't born, they're forged. And you have that fire inside you.",
          "Your courage inspires others. Don't be afraid to lead the way.",
          "Patience isn't waiting; it's keeping a good attitude while you wait.",
        ],
      },
    ),
    'Taureau': ZodiacSign(
      id: 'Taureau',
      emoji: '♉',
      elementId: 'earth',
      colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
      name: {'fr': 'Taureau', 'en': 'Taurus'},
      planet: {'fr': 'Vénus ♀', 'en': 'Venus ♀'},
      period: {'fr': '20 avril - 20 mai', 'en': 'April 20 - May 20'},
      description: {
        'fr': 'Stable, patient et sensuel. Vous appréciez les plaisirs de la vie et la sécurité.',
        'en': "Steady, patient and sensual. You enjoy life's pleasures and value security.",
      },
      traits: {
        'fr': ['Fiable', 'Patient', 'Pratique', 'Dévoué', 'Responsable', 'Stable'],
        'en': ['Reliable', 'Patient', 'Practical', 'Devoted', 'Responsible', 'Steady'],
      },
      quotes: {
        'fr': [
          'Votre persévérance est votre plus grande force. Continuez à avancer.',
          'La beauté et le confort que vous créez enrichissent le monde.',
          'Votre loyauté envers ceux que vous aimez est admirable.',
          "Prenez le temps d'apprécier les plaisirs simples de la vie.",
        ],
        'en': [
          'Your perseverance is your greatest strength. Keep moving forward.',
          'The beauty and comfort you create make the world richer.',
          'Your loyalty to the people you love is admirable.',
          "Take the time to enjoy life's simple pleasures.",
        ],
      },
    ),
    'Gémeaux': ZodiacSign(
      id: 'Gémeaux',
      emoji: '♊',
      elementId: 'air',
      colors: [Color(0xFFFBBF24), Color(0xFFFCD34D)],
      name: {'fr': 'Gémeaux', 'en': 'Gemini'},
      planet: {'fr': 'Mercure ☿', 'en': 'Mercury ☿'},
      period: {'fr': '21 mai - 20 juin', 'en': 'May 21 - June 20'},
      description: {
        'fr': 'Curieux, adaptable et communicatif. Vous excellez dans la communication et adorez apprendre.',
        'en': 'Curious, adaptable and talkative. You shine at communicating and love to learn.',
      },
      traits: {
        'fr': ['Adaptable', 'Curieux', 'Communicatif', 'Intelligent', 'Sociable', 'Vif'],
        'en': ['Adaptable', 'Curious', 'Communicative', 'Clever', 'Sociable', 'Quick-witted'],
      },
      quotes: {
        'fr': [
          'Votre curiosité naturelle est un don. Continuez à apprendre et à explorer.',
          'La communication est votre superpouvoir. Utilisez-le sagement.',
          'Votre adaptabilité vous permet de prospérer dans toute situation.',
          "Embrassez votre nature multifacette, c'est ce qui vous rend unique.",
        ],
        'en': [
          'Your natural curiosity is a gift. Keep learning and exploring.',
          'Communication is your superpower. Use it wisely.',
          'Your adaptability lets you thrive in any situation.',
          "Embrace your many sides: they're what make you unique.",
        ],
      },
    ),
    'Cancer': ZodiacSign(
      id: 'Cancer',
      emoji: '♋',
      elementId: 'water',
      colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
      name: {'fr': 'Cancer', 'en': 'Cancer'},
      planet: {'fr': 'Lune ☽', 'en': 'Moon ☽'},
      period: {'fr': '21 juin - 22 juillet', 'en': 'June 21 - July 22'},
      description: {
        'fr': 'Émotif, protecteur et intuitif. Vous êtes profondément attaché à votre famille et vos proches.',
        'en': 'Emotional, protective and intuitive. You are deeply attached to your family and loved ones.',
      },
      traits: {
        'fr': ['Intuitif', 'Protecteur', 'Loyal', 'Empathique', 'Imaginatif', 'Sensible'],
        'en': ['Intuitive', 'Protective', 'Loyal', 'Empathetic', 'Imaginative', 'Sensitive'],
      },
      quotes: {
        'fr': [
          'Votre empathie profonde est une force, pas une faiblesse.',
          "Prendre soin des autres vient naturellement, mais n'oubliez pas de prendre soin de vous.",
          'Votre intuition est puissante. Faites-lui confiance.',
          'Créer un foyer chaleureux est votre talent naturel.',
        ],
        'en': [
          'Your deep empathy is a strength, not a weakness.',
          "Caring for others comes naturally, but don't forget to care for yourself.",
          'Your intuition is powerful. Trust it.',
          'Creating a warm home is your natural talent.',
        ],
      },
    ),
    'Lion': ZodiacSign(
      id: 'Lion',
      emoji: '♌',
      elementId: 'fire',
      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      name: {'fr': 'Lion', 'en': 'Leo'},
      planet: {'fr': 'Soleil ☉', 'en': 'Sun ☉'},
      period: {'fr': '23 juillet - 22 août', 'en': 'July 23 - August 22'},
      description: {
        'fr': "Charismatique, généreux et confiant. Vous aimez être au centre de l'attention et inspirer les autres.",
        'en': 'Charismatic, generous and confident. You love the spotlight and inspiring others.',
      },
      traits: {
        'fr': ['Créatif', 'Généreux', 'Chaleureux', 'Charismatique', 'Confiant', 'Loyal'],
        'en': ['Creative', 'Generous', 'Warm', 'Charismatic', 'Confident', 'Loyal'],
      },
      quotes: {
        'fr': [
          'Votre générosité et votre chaleur illuminent la vie des autres.',
          "Vous êtes fait pour briller. N'ayez pas peur de prendre votre place.",
          'Votre confiance naturelle inspire ceux qui vous entourent.',
          "Restez fidèle à vous-même, c'est votre plus grande force.",
        ],
        'en': [
          "Your generosity and warmth light up other people's lives.",
          "You were made to shine. Don't be afraid to take your place.",
          'Your natural confidence inspires those around you.',
          "Stay true to yourself: it's your greatest strength.",
        ],
      },
    ),
    'Vierge': ZodiacSign(
      id: 'Vierge',
      emoji: '♍',
      elementId: 'earth',
      colors: [Color(0xFF059669), Color(0xFF10B981)],
      name: {'fr': 'Vierge', 'en': 'Virgo'},
      planet: {'fr': 'Mercure ☿', 'en': 'Mercury ☿'},
      period: {'fr': '23 août - 22 septembre', 'en': 'August 23 - September 22'},
      description: {
        'fr': 'Analytique, méthodique et réservé. Vous recherchez la perfection dans tout ce que vous faites.',
        'en': 'Analytical, methodical and reserved. You strive for perfection in everything you do.',
      },
      traits: {
        'fr': ['Pratique', 'Analytique', 'Travailleur', 'Fiable', 'Précis', 'Modeste'],
        'en': ['Practical', 'Analytical', 'Hard-working', 'Reliable', 'Precise', 'Modest'],
      },
      quotes: {
        'fr': [
          "Votre attention aux détails crée l'excellence dans tout ce que vous faites.",
          "Votre désir d'aider les autres rend le monde meilleur.",
          'La perfection est un voyage, pas une destination. Soyez patient avec vous-même.',
          "Votre esprit analytique résout les problèmes que d'autres ne voient même pas.",
        ],
        'en': [
          'Your eye for detail brings excellence to everything you do.',
          'Your wish to help others makes the world a better place.',
          'Perfection is a journey, not a destination. Be patient with yourself.',
          "Your analytical mind solves problems others don't even see.",
        ],
      },
    ),
    'Balance': ZodiacSign(
      id: 'Balance',
      emoji: '♎',
      elementId: 'air',
      colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
      name: {'fr': 'Balance', 'en': 'Libra'},
      planet: {'fr': 'Vénus ♀', 'en': 'Venus ♀'},
      period: {'fr': '23 septembre - 22 octobre', 'en': 'September 23 - October 22'},
      description: {
        'fr': "Social, équilibré et juste. Vous recherchez l'harmonie dans vos relations et votre environnement.",
        'en': 'Sociable, balanced and fair. You seek harmony in your relationships and surroundings.',
      },
      traits: {
        'fr': ['Diplomate', 'Juste', 'Sociable', 'Coopératif', 'Gracieux', 'Équilibré'],
        'en': ['Diplomatic', 'Fair', 'Sociable', 'Cooperative', 'Graceful', 'Balanced'],
      },
      quotes: {
        'fr': [
          "Votre quête d'harmonie apporte la paix dans votre entourage.",
          'Votre sens de la justice fait de vous un défenseur naturel.',
          'La beauté que vous créez et appréciez enrichit le monde.',
          "Trouver l'équilibre est un art, et vous êtes un artiste.",
        ],
        'en': [
          'Your search for harmony brings peace to those around you.',
          'Your sense of fairness makes you a natural advocate.',
          'The beauty you create and appreciate makes the world richer.',
          'Finding balance is an art, and you are an artist.',
        ],
      },
    ),
    'Scorpion': ZodiacSign(
      id: 'Scorpion',
      emoji: '♏',
      elementId: 'water',
      colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
      name: {'fr': 'Scorpion', 'en': 'Scorpio'},
      planet: {'fr': 'Pluton ♇', 'en': 'Pluto ♇'},
      period: {'fr': '23 octobre - 21 novembre', 'en': 'October 23 - November 21'},
      description: {
        'fr': 'Passionné, intense et mystérieux. Vous vivez vos émotions profondément et avec intensité.',
        'en': 'Passionate, intense and mysterious. You feel your emotions deeply and intensely.',
      },
      traits: {
        'fr': ['Passionné', 'Déterminé', 'Brave', 'Loyal', 'Perspicace', 'Magnétique'],
        'en': ['Passionate', 'Determined', 'Brave', 'Loyal', 'Perceptive', 'Magnetic'],
      },
      quotes: {
        'fr': [
          'Votre intensité émotionnelle est votre superpouvoir.',
          'Vous transformez chaque défi en opportunité de renaissance.',
          'Votre passion inspire et transforme ceux qui vous entourent.',
          'La profondeur de votre âme est un trésor rare.',
        ],
        'en': [
          'Your emotional intensity is your superpower.',
          'You turn every challenge into a chance to be reborn.',
          'Your passion inspires and transforms those around you.',
          'The depth of your soul is a rare treasure.',
        ],
      },
    ),
    'Sagittaire': ZodiacSign(
      id: 'Sagittaire',
      emoji: '♐',
      elementId: 'fire',
      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
      name: {'fr': 'Sagittaire', 'en': 'Sagittarius'},
      planet: {'fr': 'Jupiter ♃', 'en': 'Jupiter ♃'},
      period: {'fr': '22 novembre - 21 décembre', 'en': 'November 22 - December 21'},
      description: {
        'fr': 'Aventurier, optimiste et libre. Vous aimez explorer et découvrir de nouveaux horizons.',
        'en': 'Adventurous, optimistic and free. You love exploring and discovering new horizons.',
      },
      traits: {
        'fr': ['Optimiste', 'Aventureux', 'Honnête', 'Généreux', 'Philosophe', 'Libre'],
        'en': ['Optimistic', 'Adventurous', 'Honest', 'Generous', 'Philosophical', 'Free-spirited'],
      },
      quotes: {
        'fr': [
          'Votre optimisme est contagieux. Continuez à voir le bon côté des choses.',
          "L'aventure vous appelle. Répondez à cet appel.",
          'Votre quête de vérité et de sagesse inspire les autres.',
          'La liberté est votre droit de naissance. Vivez pleinement.',
        ],
        'en': [
          'Your optimism is contagious. Keep looking on the bright side.',
          'Adventure is calling. Answer the call.',
          'Your search for truth and wisdom inspires others.',
          'Freedom is your birthright. Live fully.',
        ],
      },
    ),
    'Capricorne': ZodiacSign(
      id: 'Capricorne',
      emoji: '♑',
      elementId: 'earth',
      colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
      name: {'fr': 'Capricorne', 'en': 'Capricorn'},
      planet: {'fr': 'Saturne ♄', 'en': 'Saturn ♄'},
      period: {'fr': '22 décembre - 19 janvier', 'en': 'December 22 - January 19'},
      description: {
        'fr': 'Ambitieux, discipliné et responsable. Vous travaillez dur pour atteindre vos objectifs.',
        'en': 'Ambitious, disciplined and responsible. You work hard to reach your goals.',
      },
      traits: {
        'fr': ['Responsable', 'Discipliné', 'Ambitieux', 'Pratique', 'Sage', 'Persévérant'],
        'en': ['Responsible', 'Disciplined', 'Ambitious', 'Practical', 'Wise', 'Persistent'],
      },
      quotes: {
        'fr': [
          'Votre discipline et votre détermination garantissent votre succès.',
          "Vous construisez des fondations solides pour l'avenir.",
          "Votre sagesse vient de l'expérience et de la réflexion.",
          'Le chemin vers le sommet est long, mais vous êtes fait pour y arriver.',
        ],
        'en': [
          'Your discipline and determination pave the way to success.',
          'You build solid foundations for the future.',
          'Your wisdom comes from experience and reflection.',
          "The road to the top is long, but you're made to get there.",
        ],
      },
    ),
    'Verseau': ZodiacSign(
      id: 'Verseau',
      emoji: '♒',
      elementId: 'air',
      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      name: {'fr': 'Verseau', 'en': 'Aquarius'},
      planet: {'fr': 'Uranus ♅', 'en': 'Uranus ♅'},
      period: {'fr': '20 janvier - 18 février', 'en': 'January 20 - February 18'},
      description: {
        'fr': 'Original, humaniste et indépendant. Vous aimez penser différemment et aider les autres.',
        'en': 'Original, humanitarian and independent. You love thinking differently and helping others.',
      },
      traits: {
        'fr': ['Original', 'Indépendant', 'Humaniste', 'Intellectuel', 'Progressiste', 'Visionnaire'],
        'en': ['Original', 'Independent', 'Humanitarian', 'Intellectual', 'Progressive', 'Visionary'],
      },
      quotes: {
        'fr': [
          'Votre vision unique change le monde pour le mieux.',
          'Votre originalité est votre plus grand atout. Ne la cachez jamais.',
          'Vous êtes en avance sur votre temps. Les autres finiront par comprendre.',
          'Votre humanisme rend le monde plus inclusif.',
        ],
        'en': [
          'Your unique vision changes the world for the better.',
          'Your originality is your greatest asset. Never hide it.',
          "You're ahead of your time. Others will catch up eventually.",
          'Your humanity makes the world more inclusive.',
        ],
      },
    ),
    'Poissons': ZodiacSign(
      id: 'Poissons',
      emoji: '♓',
      elementId: 'water',
      colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
      name: {'fr': 'Poissons', 'en': 'Pisces'},
      planet: {'fr': 'Neptune ♆', 'en': 'Neptune ♆'},
      period: {'fr': '19 février - 20 mars', 'en': 'February 19 - March 20'},
      description: {
        'fr': 'Empathique, artiste et rêveur. Vous êtes sensible et créatif avec une grande imagination.',
        'en': 'Empathetic, artistic and dreamy. You are sensitive and creative, with a vivid imagination.',
      },
      traits: {
        'fr': ['Compatissant', 'Artiste', 'Intuitif', 'Doux', 'Sage', 'Musical'],
        'en': ['Compassionate', 'Artistic', 'Intuitive', 'Gentle', 'Wise', 'Musical'],
      },
      quotes: {
        'fr': [
          "Votre créativité et votre imagination n'ont pas de limites.",
          'Votre compassion guérit les âmes blessées.',
          "Vos rêves sont des visions d'un monde meilleur.",
          'Votre sensibilité artistique crée de la magie dans le monde.',
        ],
        'en': [
          'Your creativity and imagination know no limits.',
          'Your compassion heals wounded souls.',
          'Your dreams are visions of a better world.',
          'Your artistic sensitivity brings magic into the world.',
        ],
      },
    ),
  };
}
