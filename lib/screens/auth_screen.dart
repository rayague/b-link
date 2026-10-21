import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_links.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';
import 'onboarding_screen.dart' show AppLogo;

/// Connexion avec Google.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'AuthScreen');
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/');
      return;
    }
    setState(() {
      _loading = false;
      // Fenêtre Google fermée : rien à signaler.
      _error = auth.lastSignInCancelled
          ? null
          : AppLocalizations.of(context).translate('signInFailed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.page),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 88)),
                    const SizedBox(height: Space.xl),
                    Text('B-Link',
                        style: t.displaySmall, textAlign: TextAlign.center),
                    const SizedBox(height: Space.s),
                    Text(
                      l10n.translate('authTagline'),
                      style: t.bodyLarge?.copyWith(color: c.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Space.xxl + Space.s),
                    GlassCard(
                      padding: const EdgeInsets.all(Space.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.translate('welcomeBack'),
                              style: t.titleLarge),
                          const SizedBox(height: Space.xs),
                          Text(l10n.translate('signInSubtitle'),
                              style: t.bodyMedium
                                  ?.copyWith(color: c.onSurfaceVariant)),
                          const SizedBox(height: Space.xl),
                          _GoogleButton(loading: _loading, onPressed: _signIn),
                          if (_error != null) ...[
                            const SizedBox(height: Space.m),
                            NoticeCard(
                              icon: Icons.error_outline_rounded,
                              text: _error!,
                              tone: Tone.danger,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.xl),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse(AppLinks.privacy),
                          mode: LaunchMode.externalApplication),
                      child: Text(
                        l10n.translate('authDisclaimer'),
                        style: t.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton « Continuer avec Google » (fond blanc et logo, conformes aux
/// consignes de Google, dans les deux thèmes).
class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _GoogleButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F1F1F),
        disabledBackgroundColor: Colors.white70,
        side: const BorderSide(color: Color(0xFFDADCE0)),
      ),
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF1F1F1F)))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox.square(
                    dimension: 20, child: CustomPaint(painter: _GoogleLogo())),
                const SizedBox(width: Space.m),
                Text(l10n.translate('signInWithGoogle')),
              ],
            ),
    );
  }
}

/// Logo « G » de Google dessiné (évite une image).
class _GoogleLogo extends CustomPainter {
  const _GoogleLogo();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, w / 2);
    final r = w * 0.4;
    final stroke = w * 0.2;
    final rect = Rect.fromCircle(center: center, radius: r);
    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, -0.45, 1.25, false, arc(const Color(0xFF4285F4)));
    canvas.drawArc(rect, 0.8, 1.45, false, arc(const Color(0xFF34A853)));
    canvas.drawArc(rect, 2.25, 0.95, false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, 3.2, 1.7, false, arc(const Color(0xFFEA4335)));
    canvas.drawRect(
      Rect.fromLTWH(w / 2, w / 2 - stroke / 2, r + stroke / 2, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
