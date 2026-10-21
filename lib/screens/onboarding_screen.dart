import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_scenes.dart';
import '../widgets/ui/glass.dart';

/// Quatre écrans de présentation animés, puis la connexion.
///
/// Chaque page a sa scène (rappels, jumeaux, message, ciel). Le texte et
/// l'illustration suivent le doigt avec un léger décalage (parallaxe) ; les
/// animations s'arrêtent si l'appareil demande moins de mouvement.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pages = PageController();
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 8));
  int _page = 0;

  static const _count = 4;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'OnboardingScreen');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _loop
        ..stop()
        ..value = 0.7; // scènes figées dans un bel état (message écrit)
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _finish() => Navigator.of(context).pushReplacementNamed('/auth');

  void _next() => _pages.nextPage(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic);

  /// Position de la page [i] par rapport au centre (0 = centrée).
  double _delta(int i) {
    if (!_pages.hasClients || !_pages.position.haveDimensions) {
      return (i - _page).toDouble();
    }
    return i - (_pages.page ?? _page.toDouble());
  }

  Widget _scene(int i, double focus) => switch (i) {
        0 => ReminderScene(loop: _loop, focus: focus),
        1 => TwinsScene(loop: _loop, focus: focus),
        2 => MessageScene(loop: _loop, focus: focus),
        _ => SkyScene(loop: _loop, focus: focus),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final last = _page == _count - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: Stack(
          children: [
            // Teinte de fond qui glisse d'une page à l'autre.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pages,
                builder: (context, _) {
                  final p = _pages.hasClients && _pages.position.haveDimensions
                      ? (_pages.page ?? 0)
                      : _page.toDouble();
                  // Ardoise sur les pages paires, or sur les impaires.
                  final gold = 0.5 - 0.5 * math.cos(math.pi * p);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.35),
                        radius: 0.9,
                        colors: [
                          Color.lerp(c.primary, c.secondary, gold)!
                              .withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.page),
                    child: SizedBox(
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
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: _count,
                      onPageChanged: (p) => setState(() => _page = p),
                      itemBuilder: (context, i) => AnimatedBuilder(
                        animation: _pages,
                        builder: (context, _) {
                          final d = _delta(i);
                          final focus = (1 - d.abs()).clamp(0.0, 1.0);
                          return _OnboardingPage(
                            index: i,
                            delta: d,
                            scene: RepaintBoundary(child: _scene(i, focus)),
                          );
                        },
                      ),
                    ),
                  ),
                  _Indicator(controller: _pages, count: _count, page: _page),
                  const SizedBox(height: Space.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.page),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: last ? _finish : _next,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(
                                      begin: const Offset(0, 0.4),
                                      end: Offset.zero)
                                  .animate(a),
                              child: child,
                            ),
                          ),
                          child: Row(
                            key: ValueKey(last),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  l10n.translate(last ? 'getStarted' : 'next')),
                              const SizedBox(width: Space.s),
                              Icon(
                                  last
                                      ? Icons.celebration_outlined
                                      : Icons.arrow_forward_rounded,
                                  size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une page : la scène, puis le titre et le texte, avec une parallaxe.
class _OnboardingPage extends StatelessWidget {
  final int index;
  final double delta;
  final Widget scene;
  const _OnboardingPage(
      {required this.index, required this.delta, required this.scene});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final away = delta.abs().clamp(0.0, 1.0);
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      // L'illustration glisse moins vite que la page, le texte un peu plus.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.page),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Transform.translate(
                  offset: Offset(delta * w * 0.35, 0),
                  child: Transform.scale(
                    scale: 1 - 0.12 * away,
                    child: Opacity(
                      opacity: (1 - away * 0.9).clamp(0.0, 1.0),
                      child: FittedBox(child: scene),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-delta * w * 0.25, 0),
              child: Opacity(
                opacity: (1 - away * 1.6).clamp(0.0, 1.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    children: [
                      Text(
                        l10n.translate('onboarding${index + 1}Title'),
                        style: t.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Space.m),
                      Text(
                        l10n.translate('onboarding${index + 1}Body'),
                        style: t.bodyLarge
                            ?.copyWith(color: c.onSurfaceVariant, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.xl),
          ],
        ),
      );
    });
  }
}

/// Points de pagination : le point actif s'étire et suit le doigt.
class _Indicator extends StatelessWidget {
  final PageController controller;
  final int count;
  final int page;
  const _Indicator(
      {required this.controller, required this.count, required this.page});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final p = controller.hasClients && controller.position.haveDimensions
            ? (controller.page ?? page.toDouble())
            : page.toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              Builder(builder: (context) {
                final a = (1 - (p - i).abs()).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8 + 20 * a,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color.lerp(c.outlineVariant, c.primary, a),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
          ],
        );
      },
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
