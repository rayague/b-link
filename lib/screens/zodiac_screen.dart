import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../l10n/app_localizations.dart';
import 'dart:math' as math;

class ZodiacScreen extends StatefulWidget {
  static const routeName = '/zodiac';
  const ZodiacScreen({super.key});

  @override
  State<ZodiacScreen> createState() => _ZodiacScreenState();
}

class _ZodiacScreenState extends State<ZodiacScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = context.watch<ProfileProvider>().profile;
    final loc = AppLocalizations.of(context);

    if (profile == null || profile.zodiac == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('yourZodiacSign')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.stars,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                loc.translate('chooseBirthDate'),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final zodiacSign = profile.zodiac!;
    final emoji = _zodiacEmoji(zodiacSign);
    final colors = _zodiacColors(zodiacSign);
    final quotes = _zodiacQuotes(zodiacSign);
    final traits = _zodiacTraits(zodiacSign);
    final element = _zodiacElement(zodiacSign);
    final planet = _zodiacPlanet(zodiacSign);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                : [const Color(0xFFF9FAFB), Colors.white],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 250,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Animated stars background
                      ...List.generate(20, (i) {
                        final random = math.Random(i);
                        return Positioned(
                          left: random.nextDouble() * 400,
                          top: random.nextDouble() * 250,
                          child: Icon(
                            Icons.star,
                            size: 10 + random.nextDouble() * 15,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        );
                      }),
                      FlexibleSpaceBar(
                        titlePadding:
                            const EdgeInsets.only(left: 60, bottom: 16),
                        title: Text(
                          zodiacSign,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        background: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 50),
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 70),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.water_drop,
                                title: 'Élément',
                                value: element,
                                gradient: const [
                                  Color(0xFF3B82F6),
                                  Color(0xFF60A5FA)
                                ],
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.public,
                                title: 'Planète',
                                value: planet,
                                gradient: const [
                                  Color(0xFF8B5CF6),
                                  Color(0xFFA78BFA)
                                ],
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Traits
                        _buildTraitsCard(traits, isDark),
                        const SizedBox(height: 20),

                        // Daily Quotes
                        Text(
                          loc.translate('zodiacQuotes'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        ...quotes.asMap().entries.map((entry) {
                          return _buildQuoteCard(
                            entry.value,
                            colors,
                            isDark,
                            entry.key * 100,
                          );
                        }).toList(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required List<Color> gradient,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitsCard(List<String> traits, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF374151), const Color(0xFF1F2937)]
              : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.psychology, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Traits de personnalité',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: traits
                .map((trait) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        trait,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF78350F),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(
      String quote, List<Color> colors, bool isDark, int delay) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF374151), const Color(0xFF1F2937)]
                : [Colors.white, Colors.grey[50]!],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors[0].withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.format_quote,
              color: colors[0],
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                quote,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _zodiacEmoji(String sign) {
    switch (sign) {
      case 'Bélier':
        return '♈';
      case 'Taureau':
        return '♉';
      case 'Gémeaux':
        return '♊';
      case 'Cancer':
        return '♋';
      case 'Lion':
        return '♌';
      case 'Vierge':
        return '♍';
      case 'Balance':
        return '♎';
      case 'Scorpion':
        return '♏';
      case 'Sagittaire':
        return '♐';
      case 'Capricorne':
        return '♑';
      case 'Verseau':
        return '♒';
      case 'Poissons':
        return '♓';
      default:
        return '✨';
    }
  }

  List<Color> _zodiacColors(String sign) {
    switch (sign) {
      case 'Bélier':
        return [const Color(0xFFDC2626), const Color(0xFFEF4444)];
      case 'Taureau':
        return [const Color(0xFF16A34A), const Color(0xFF22C55E)];
      case 'Gémeaux':
        return [const Color(0xFFFBBF24), const Color(0xFFFCD34D)];
      case 'Cancer':
        return [const Color(0xFF6366F1), const Color(0xFF818CF8)];
      case 'Lion':
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case 'Vierge':
        return [const Color(0xFF059669), const Color(0xFF10B981)];
      case 'Balance':
        return [const Color(0xFFEC4899), const Color(0xFFF472B6)];
      case 'Scorpion':
        return [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)];
      case 'Sagittaire':
        return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)];
      case 'Capricorne':
        return [const Color(0xFF0891B2), const Color(0xFF06B6D4)];
      case 'Verseau':
        return [const Color(0xFF3B82F6), const Color(0xFF60A5FA)];
      case 'Poissons':
        return [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)];
      default:
        return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)];
    }
  }

  List<String> _zodiacQuotes(String sign) {
    final Map<String, List<String>> quotes = {
      'Bélier': [
        "Votre énergie naturelle vous pousse à l'action. Canalisez-la vers vos objectifs.",
        "Les leaders ne naissent pas, ils se forgent. Et vous avez cette flamme en vous.",
        "Votre courage inspire les autres. N'ayez pas peur de montrer la voie.",
        "La patience n'est pas l'attente, mais garder une bonne attitude en attendant.",
      ],
      'Taureau': [
        "Votre persévérance est votre plus grande force. Continuez à avancer.",
        "La beauté et le confort que vous créez enrichissent le monde.",
        "Votre loyauté envers ceux que vous aimez est admirable.",
        "Prenez le temps d'apprécier les plaisirs simples de la vie.",
      ],
      'Gémeaux': [
        "Votre curiosité naturelle est un don. Continuez à apprendre et à explorer.",
        "La communication est votre superpouvoir. Utilisez-le sagement.",
        "Votre adaptabilité vous permet de prospérer dans toute situation.",
        "Embrassez votre nature multifacette, c'est ce qui vous rend unique.",
      ],
      'Cancer': [
        "Votre empathie profonde est une force, pas une faiblesse.",
        "Prendre soin des autres vient naturellement, mais n'oubliez pas de prendre soin de vous.",
        "Votre intuition est puissante. Faites-lui confiance.",
        "Créer un foyer chaleureux est votre talent naturel.",
      ],
      'Lion': [
        "Votre générosité et votre chaleur illuminent la vie des autres.",
        "Vous êtes né pour briller. N'ayez pas peur de prendre votre place.",
        "Votre confiance naturelle inspire ceux qui vous entourent.",
        "Restez fidèle à vous-même, c'est votre plus grande force.",
      ],
      'Vierge': [
        "Votre attention aux détails crée l'excellence dans tout ce que vous faites.",
        "Votre désir d'aider les autres rend le monde meilleur.",
        "La perfection est un voyage, pas une destination. Soyez patient avec vous-même.",
        "Votre esprit analytique résout les problèmes que d'autres ne voient même pas.",
      ],
      'Balance': [
        "Votre quête d'harmonie apporte la paix dans votre entourage.",
        "Votre sens de la justice fait de vous un défenseur naturel.",
        "La beauté que vous créez et appréciez enrichit le monde.",
        "Trouver l'équilibre est un art, et vous êtes un artiste.",
      ],
      'Scorpion': [
        "Votre intensité émotionnelle est votre superpouvoir.",
        "Vous transformez chaque défi en opportunité de renaissance.",
        "Votre passion inspire et transforme ceux qui vous entourent.",
        "La profondeur de votre âme est un trésor rare.",
      ],
      'Sagittaire': [
        "Votre optimisme est contagieux. Continuez à voir le bon côté des choses.",
        "L'aventure vous appelle. Répondez à cet appel.",
        "Votre quête de vérité et de sagesse inspire les autres.",
        "La liberté est votre droit de naissance. Vivez pleinement.",
      ],
      'Capricorne': [
        "Votre discipline et votre détermination garantissent votre succès.",
        "Vous construisez des fondations solides pour l'avenir.",
        "Votre sagesse vient de l'expérience et de la réflexion.",
        "Le chemin vers le sommet est long, mais vous êtes fait pour y arriver.",
      ],
      'Verseau': [
        "Votre vision unique change le monde pour le mieux.",
        "Votre originalité est votre plus grand atout. Ne la cachez jamais.",
        "Vous êtes en avance sur votre temps. Les autres finiront par comprendre.",
        "Votre humanitarisme rend le monde plus inclusif.",
      ],
      'Poissons': [
        "Votre créativité et votre imagination n'ont pas de limites.",
        "Votre compassion guérit les âmes blessées.",
        "Vos rêves sont des visions d'un monde meilleur.",
        "Votre sensibilité artistique crée de la magie dans le monde.",
      ],
    };
    return quotes[sign] ?? ['Vous êtes unique et spécial.'];
  }

  List<String> _zodiacTraits(String sign) {
    final Map<String, List<String>> traits = {
      'Bélier': [
        'Courageux',
        'Énergique',
        'Déterminé',
        'Confiant',
        'Passionné',
        'Leader'
      ],
      'Taureau': [
        'Fiable',
        'Patient',
        'Pratique',
        'Dévoué',
        'Responsable',
        'Stable'
      ],
      'Gémeaux': [
        'Adaptable',
        'Curieux',
        'Communicatif',
        'Intelligent',
        'Sociable',
        'Vif'
      ],
      'Cancer': [
        'Intuitif',
        'Protecteur',
        'Loyal',
        'Empathique',
        'Imaginatif',
        'Sensible'
      ],
      'Lion': [
        'Créatif',
        'Généreux',
        'Chaleureux',
        'Charismatique',
        'Confiant',
        'Loyal'
      ],
      'Vierge': [
        'Pratique',
        'Analytique',
        'Travailleur',
        'Fiable',
        'Précis',
        'Modeste'
      ],
      'Balance': [
        'Diplomatique',
        'Juste',
        'Social',
        'Coopératif',
        'Gracieux',
        'Équilibré'
      ],
      'Scorpion': [
        'Passionné',
        'Déterminé',
        'Brave',
        'Loyal',
        'Perspicace',
        'Magnétique'
      ],
      'Sagittaire': [
        'Optimiste',
        'Aventureux',
        'Honnête',
        'Généreux',
        'Philosophique',
        'Libre'
      ],
      'Capricorne': [
        'Responsable',
        'Discipliné',
        'Ambitieux',
        'Pratique',
        'Sage',
        'Persévérant'
      ],
      'Verseau': [
        'Original',
        'Indépendant',
        'Humanitaire',
        'Intellectuel',
        'Progressiste',
        'Visionnaire'
      ],
      'Poissons': [
        'Compatissant',
        'Artistique',
        'Intuitif',
        'Doux',
        'Sage',
        'Musical'
      ],
    };
    return traits[sign] ?? ['Unique'];
  }

  String _zodiacElement(String sign) {
    if (['Bélier', 'Lion', 'Sagittaire'].contains(sign)) return 'Feu 🔥';
    if (['Taureau', 'Vierge', 'Capricorne'].contains(sign)) return 'Terre 🌍';
    if (['Gémeaux', 'Balance', 'Verseau'].contains(sign)) return 'Air 💨';
    if (['Cancer', 'Scorpion', 'Poissons'].contains(sign)) return 'Eau 💧';
    return 'Inconnu';
  }

  String _zodiacPlanet(String sign) {
    switch (sign) {
      case 'Bélier':
        return 'Mars ♂';
      case 'Taureau':
        return 'Vénus ♀';
      case 'Gémeaux':
        return 'Mercure ☿';
      case 'Cancer':
        return 'Lune ☽';
      case 'Lion':
        return 'Soleil ☉';
      case 'Vierge':
        return 'Mercure ☿';
      case 'Balance':
        return 'Vénus ♀';
      case 'Scorpion':
        return 'Pluton ♇';
      case 'Sagittaire':
        return 'Jupiter ♃';
      case 'Capricorne':
        return 'Saturne ♄';
      case 'Verseau':
        return 'Uranus ♅';
      case 'Poissons':
        return 'Neptune ♆';
      default:
        return 'Inconnu';
    }
  }
}
