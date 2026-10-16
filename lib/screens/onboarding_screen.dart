import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/glass.dart';

/// Trois écrans de présentation, puis la connexion.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _icons = [
    Icons.cake_outlined,
    Icons.public_rounded,
    Icons.edit_note_rounded,
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'OnboardingScreen');
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() => Navigator.of(context).pushReplacementNamed('/auth');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final last = _page == _icons.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Column(
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      const AppLogo(size: 32),
                      const SizedBox(width: Space.s),
                      Text('B-Link', style: t.titleMedium),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: last ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: last ? null : _finish,
                          child: Text(l10n.translate('skip')),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _icons.length,
                    onPageChanged: (p) => setState(() => _page = p),
                    itemBuilder: (context, i) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlassCard(
                              borderRadius: BorderRadius.circular(48),
                              padding: const EdgeInsets.all(Space.xxl),
                              child: Icon(_icons[i],
                                  size: 56,
                                  color: i == 1 ? c.secondary : c.primary),
                            ),
                            const SizedBox(height: Space.xxl + Space.s),
                            Text(
                              l10n.translate('onboarding${i + 1}Title'),
                              style: t.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: Space.m),
                            Text(
                              l10n.translate('onboarding${i + 1}Body'),
                              style: t.bodyLarge
                                  ?.copyWith(color: c.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _icons.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? c.primary : c.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Space.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: last
                        ? _finish
                        : () => _pages.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            ),
                    child: Text(l10n.translate(last ? 'getStarted' : 'next')),
                  ),
                ),
                const SizedBox(height: Space.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icône de l'application, arrondie.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        cacheWidth: (size * 3).round(),
        fit: BoxFit.cover,
      ),
    );
  }
}
