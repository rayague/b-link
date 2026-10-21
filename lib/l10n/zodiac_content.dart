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
        'fr': "L'élan, le courage et la franchise. Vous ouvrez la voie et donnez aux autres l'envie d'oser.",
        'en': 'Drive, courage and honesty. You lead the way and make others want to dare.',
      },
      traits: {
        'fr': ['Courage', 'Énergie', 'Détermination', 'Confiance', 'Passion', 'Leadership'],
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
        'fr': 'La douceur, la patience et le goût des belles choses. Vous construisez ce qui dure.',
        'en': 'Gentleness, patience and a love of beautiful things. You build what lasts.',
      },
      traits: {
        'fr': ['Fiabilité', 'Patience', 'Sens pratique', 'Dévouement', 'Responsabilité', 'Stabilité'],
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
        'fr': "La curiosité, l'esprit et les mots justes. Avec vous, chaque conversation devient une aventure.",
        'en': 'Curiosity, wit and the right words. With you, every conversation becomes an adventure.',
      },
      traits: {
        'fr': ['Adaptabilité', 'Curiosité', 'Communication', 'Intelligence', 'Sociabilité', 'Vivacité'],
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
        'fr': "La tendresse, l'intuition et la loyauté. Auprès de vous, chacun se sent chez soi.",
        'en': 'Tenderness, intuition and loyalty. Around you, everyone feels at home.',
      },
      traits: {
        'fr': ['Intuition', 'Protection', 'Loyauté', 'Empathie', 'Imagination', 'Sensibilité'],
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
        'fr': 'La générosité, le charisme et un cœur immense. Vous rayonnez et faites briller les autres.',
        'en': 'Generosity, charisma and a huge heart. You shine, and you make others shine.',
      },
      traits: {
        'fr': ['Créativité', 'Générosité', 'Chaleur', 'Charisme', 'Confiance', 'Loyauté'],
        'en': ['Creative', 'Generous', 'Warm', 'Charismatic', 'Confident', 'Loyal'],
      },
      quotes: {
        'fr': [
          'Votre générosité et votre chaleur illuminent la vie des autres.',
          "Vous avez tout pour briller. N'ayez pas peur de prendre votre place.",
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
        'fr': "L'attention, la précision et le dévouement. Vous rendez le monde plus juste, détail après détail.",
        'en': 'Attention, precision and devotion. You make the world more right, one detail at a time.',
      },
      traits: {
        'fr': ['Sens pratique', 'Analyse', 'Ardeur au travail', 'Fiabilité', 'Précision', 'Modestie'],
        'en': ['Practical', 'Analytical', 'Hard-working', 'Reliable', 'Precise', 'Modest'],
      },
      quotes: {
        'fr': [
          "Votre attention aux détails crée l'excellence dans tout ce que vous faites.",
          "Votre désir d'aider les autres rend le monde meilleur.",
          'La perfection est un voyage, pas une destination. Accordez-vous de la douceur.',
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
        'fr': "L'harmonie, l'élégance et le sens de la justice. Vous savez rapprocher les gens.",
        'en': 'Harmony, elegance and a sense of justice. You know how to bring people together.',
      },
      traits: {
        'fr': ['Diplomatie', 'Justice', 'Sociabilité', 'Coopération', 'Grâce', 'Équilibre'],
        'en': ['Diplomatic', 'Fair', 'Sociable', 'Cooperative', 'Graceful', 'Balanced'],
      },
      quotes: {
        'fr': [
          "Votre quête d'harmonie apporte la paix dans votre entourage.",
          'Votre sens de la justice fait de vous un défenseur naturel.',
          'La beauté que vous créez et appréciez enrichit le monde.',
          "Trouver l'équilibre est un art, et c'est le vôtre.",
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
        'fr': 'La profondeur, l’intensité et une loyauté absolue. Vous vivez tout pleinement.',
        'en': 'Depth, intensity and absolute loyalty. You live everything fully.',
      },
      traits: {
        'fr': ['Passion', 'Détermination', 'Bravoure', 'Loyauté', 'Perspicacité', 'Magnétisme'],
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
        'fr': "L'optimisme, la liberté et la soif de découvrir. Avec vous, l'horizon s'élargit.",
        'en': 'Optimism, freedom and a thirst for discovery. With you, the horizon widens.',
      },
      traits: {
        'fr': ['Optimisme', "Goût de l'aventure", 'Honnêteté', 'Générosité', 'Sagesse', 'Liberté'],
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
        'fr': 'La détermination, la sagesse et la constance. Vous gravissez vos sommets pas à pas.',
        'en': 'Determination, wisdom and constancy. You climb your summits step by step.',
      },
      traits: {
        'fr': ['Responsabilité', 'Discipline', 'Ambition', 'Sens pratique', 'Sagesse', 'Persévérance'],
        'en': ['Responsible', 'Disciplined', 'Ambitious', 'Practical', 'Wise', 'Persistent'],
      },
      quotes: {
        'fr': [
          'Votre discipline et votre détermination vous mènent loin.',
          "Vous construisez des fondations solides pour l'avenir.",
          "Votre sagesse vient de l'expérience et de la réflexion.",
          'Le chemin vers le sommet est long, mais vous avez tout pour y arriver.',
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
        'fr': "L'originalité, l'humanisme et la liberté. Vous imaginez demain avant tout le monde.",
        'en': 'Originality, humanism and freedom. You imagine tomorrow before anyone else.',
      },
      traits: {
        'fr': ['Originalité', 'Indépendance', 'Humanisme', 'Curiosité intellectuelle', 'Esprit de progrès', 'Vision'],
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
        'fr': "L'empathie, l'imagination et une douceur infinie. Vous ressentez le monde comme personne.",
        'en': 'Empathy, imagination and endless gentleness. You feel the world like no one else.',
      },
      traits: {
        'fr': ['Compassion', 'Sens artistique', 'Intuition', 'Douceur', 'Sagesse', 'Musicalité'],
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
