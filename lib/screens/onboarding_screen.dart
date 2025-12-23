import 'package:flutter/material.dart';
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
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    AnalyticsService().logScreenView(
      screenName: 'OnboardingScreen',
      screenClass: 'OnboardingScreen',
    );
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _animationController.reset();
    _animationController.forward();
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
        gradient: const [Color(0xFFEC4899), Color(0xFFF472B6)],
        illustration: '🎂',
      ),
      _OnboardingPageData(
        icon: Icons.notifications_active_rounded,
        title: loc.translate('onboarding2Title'),
        description: loc.translate('onboarding2Body'),
        gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
        illustration: '🔔',
      ),
      _OnboardingPageData(
        icon: Icons.favorite_rounded,
        title: loc.translate('onboarding3Title'),
        description: loc.translate('onboarding3Body'),
        gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        illustration: '💌',
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E3A8A), const Color(0xFF1F2937)]
                : [Colors.white, const Color(0xFFF9FAFB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with skip button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cake_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'B-Link',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    // Skip button
                    if (_currentPage < 2)
                      TextButton(
                        onPressed: _navigateToAuth,
                        child: Text(
                          loc.translate('skip'),
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return ScaleTransition(
                      scale: _currentPage == index
                          ? _scaleAnimation
                          : const AlwaysStoppedAnimation(1.0),
                      child: _OnboardingPage(
                        data: pages[index],
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),

              // Dots indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: _currentPage == index
                            ? LinearGradient(colors: pages[index].gradient)
                            : null,
                        color: _currentPage == index
                            ? null
                            : isDark
                                ? Colors.grey[700]
                                : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _currentPage == pages.length - 1
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: pages[_currentPage].gradient),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: pages[_currentPage]
                                    .gradient[0]
                                    .withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _navigateToAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  loc.translate('getStarted'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white),
                              ],
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: pages[_currentPage].gradient[0],
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                loc.translate('next'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: pages[_currentPage].gradient[0],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: pages[_currentPage].gradient[0],
                              ),
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

  const _OnboardingPage({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: data.gradient.map((c) => c.withOpacity(0.2)).toList(),
              ),
              border: Border.all(
                color: data.gradient[0].withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: data.gradient),
                  boxShadow: [
                    BoxShadow(
                      color: data.gradient[0].withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    data.illustration,
                    style: const TextStyle(fontSize: 70),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Feature icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureDot(data.gradient[0]),
              const SizedBox(width: 8),
              _buildFeatureDot(data.gradient[0].withOpacity(0.6)),
              const SizedBox(width: 8),
              _buildFeatureDot(data.gradient[0].withOpacity(0.3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
