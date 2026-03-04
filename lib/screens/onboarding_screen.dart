import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();

    AnalyticsService().logScreenView(
      screenName: 'OnboardingScreen',
      screenClass: 'OnboardingScreen',
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _slideController.reset();
    _slideController.forward();
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _OnboardingPageData(
        icon: Icons.cake_rounded,
        title: loc.translate('onboarding1Title'),
        description: loc.translate('onboarding1Body'),
        gradient: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
        illustration: '🎂',
      ),
      _OnboardingPageData(
        icon: Icons.people_rounded,
        title: loc.translate('onboarding2Title'),
        description: loc.translate('onboarding2Body'),
        gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
        illustration: '👥',
      ),
      _OnboardingPageData(
        icon: Icons.notifications_rounded,
        title: loc.translate('onboarding3Title'),
        description: loc.translate('onboarding3Body'),
        gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
        illustration: '🔔',
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [Colors.white, Colors.grey.shade50],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar with animated logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Animated Logo
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.05),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: pages[_currentPage].gradient,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: pages[_currentPage].gradient[0].withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.cake_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: pages[_currentPage].gradient,
                                  ).createShader(bounds),
                                  child: Text(
                                    'B-Link',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Skip button with animation
                      if (_currentPage < 2)
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 300),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: TextButton(
                                onPressed: _navigateToAuth,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  loc.translate('skip'),
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                // Le contenu principal prend tout l'espace restant
                Expanded(
                  child: Column(
                    children: [
                      // PageView with parallax effect
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: pages.length,
                          itemBuilder: (context, index) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.3, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _slideController,
                                curve: Curves.easeOutCubic,
                              )),
                              child: FadeTransition(
                                opacity: _slideController,
                                child: _OnboardingPage(
                                  data: pages[index],
                                  isDark: isDark,
                                  floatingAnimation: _floatingController,
                                  rotateAnimation: _rotateController,
                                  isActive: _currentPage == index,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Modern dots indicator with liquid animation
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: _currentPage == index ? 40 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: _currentPage == index
                              ? LinearGradient(colors: pages[_currentPage].gradient)
                              : null,
                          color: _currentPage == index
                              ? null
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.1),
                          boxShadow: _currentPage == index
                              ? [
                                  BoxShadow(
                                    color: pages[_currentPage].gradient[0].withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom button with morphing animation
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    width: double.infinity,
                    height: 60,
                    child: _currentPage == pages.length - 1
                        ? AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.02),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: pages[_currentPage].gradient,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: pages[_currentPage].gradient[0].withValues(alpha: 0.5),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _navigateToAuth,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              loc.translate('getStarted'),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                width: 2,
                                color: pages[_currentPage].gradient[0],
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  pages[_currentPage].gradient[0].withValues(alpha: 0.1),
                                  pages[_currentPage].gradient[1].withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOutCubic,
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: pages[_currentPage].gradient,
                                        ).createShader(bounds),
                                        child: Text(
                                          loc.translate('next'),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: pages[_currentPage].gradient,
                                        ).createShader(bounds),
                                        child: const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),                   // closes SafeArea
        ],               // closes Stack.children
      ),                 // closes Stack
    );                   // closes Scaffold
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final String illustration;

  _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.illustration,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isDark;
  final Animation<double> floatingAnimation;
  final Animation<double> rotateAnimation;
  final bool isActive;

  const _OnboardingPage({
    required this.data,
    required this.isDark,
    required this.floatingAnimation,
    required this.rotateAnimation,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
            // 3D-like floating illustration
            AnimatedBuilder(
              animation: Listenable.merge([floatingAnimation, rotateAnimation]),
              builder: (context, child) {
                final float = math.sin(floatingAnimation.value * 2 * math.pi) * 15;
                return Transform.translate(
                  offset: Offset(0, float),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer rotating ring
                      Transform.rotate(
                        angle: rotateAnimation.value * 2 * math.pi,
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                data.gradient[0].withValues(alpha: 0.0),
                                data.gradient[0].withValues(alpha: 0.3),
                                data.gradient[1].withValues(alpha: 0.3),
                                data.gradient[0].withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Middle glow ring
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              data.gradient[0].withValues(alpha: 0.0),
                              data.gradient[0].withValues(alpha: 0.15),
                              data.gradient[1].withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                      // Main circle with glassmorphism
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              data.gradient[0],
                              data.gradient[1],
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: data.gradient[0].withValues(alpha: 0.4),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: data.gradient[1].withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, -10),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              data.illustration,
                              style: const TextStyle(fontSize: 90),
                            ),
                          ),
                        ),
                      ),
                      // Sparkle effects
                      ...List.generate(6, (index) {
                        final angle = (index * 60.0) + (rotateAnimation.value * 360);
                        final radian = angle * math.pi / 180;
                        final distance = 110.0;
                        return Transform.translate(
                          offset: Offset(
                            math.cos(radian) * distance,
                            math.sin(radian) * distance,
                          ),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: data.gradient[index % 2],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: data.gradient[index % 2].withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 64),

            // Title with gradient text
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: data.gradient,
              ).createShader(bounds),
              child: Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description with fade-in effect
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Animated feature indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder(
                  duration: Duration(milliseconds: 600 + (index * 100)),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              data.gradient[0].withValues(alpha: 1 - (index * 0.3)),
                              data.gradient[1].withValues(alpha: 1 - (index * 0.3)),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: data.gradient[0].withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
        }, // <-- ferme builder
      ), // <-- ferme LayoutBuilder
    ); // <-- ferme Padding
  }
}