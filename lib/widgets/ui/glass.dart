import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Fond de page : teinte neutre et deux halos très doux (ardoise, or) qui
/// donnent de la matière au verre posé dessus. Statique : rien n'est animé,
/// rien n'est recalculé au défilement.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final g = Glass.of(context);
    return ColoredBox(
      color: g.backdrop,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: LayoutBuilder(builder: (context, box) {
              final d = box.biggest.shortestSide;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: -d * 0.45,
                    top: -d * 0.35,
                    child: _Bloom(color: g.bloomA, diameter: d * 1.3),
                  ),
                  Positioned(
                    right: -d * 0.5,
                    bottom: -d * 0.2,
                    child: _Bloom(color: g.bloomB, diameter: d * 1.2),
                  ),
                ],
              );
            }),
          ),
          child,
        ],
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  final Color color;
  final double diameter;
  const _Bloom({required this.color, required this.diameter});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: diameter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      );
}

/// Surface de verre : remplissage translucide, reflet, liseré de 1 px.
///
/// [blur] applique un vrai flou d'arrière-plan. Il coûte cher : on le
/// réserve aux surfaces qui passent au-dessus du contenu (barres, feuilles).
/// Sur le fond ambiant, les cartes n'en ont pas besoin pour paraître
/// dépolies.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final bool blur;

  /// Teinte optionnelle (mise en avant), mélangée au verre.
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.l),
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.blur = false,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final g = Glass.of(context);
    final radius = borderRadius ?? BorderRadius.circular(Radii.card);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final base = tint == null
        ? g.fill
        : Color.alphaBlend(
            tint!.withValues(alpha: isLight ? 0.14 : 0.08), g.fill);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.alphaBlend(g.highlight, base), base],
          stops: const [0, 0.55],
        ),
        border: Border.all(color: g.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (blur) {
      surface = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: g.blur, sigmaY: g.blur),
          child: surface,
        ),
      );
    }
    // Pas d'ombre : à travers un verre translucide elle se verrait comme
    // un rebord gris sous la carte.
    return surface;
  }
}

/// Barre d'application en verre. Transparente en haut de page ; dès que le
/// contenu passe dessous, un verre dépoli apparaît en fondu et le floute.
class GlassAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<GlassAppBar> createState() => _GlassAppBarState();
}

class _GlassAppBarState extends State<GlassAppBar> {
  ScrollNotificationObserverState? _observer;
  bool _scrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_onScroll);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll(ScrollNotification n) {
    // Seule la liste principale de la page compte (pas un carrousel).
    if (n is! ScrollUpdateNotification || n.depth != 0) return;
    if (n.metrics.axis != Axis.vertical) return;
    final under = n.metrics.extentBefore > 0;
    if (under != _scrolledUnder) setState(() => _scrolledUnder = under);
  }

  @override
  Widget build(BuildContext context) {
    final g = Glass.of(context);
    final c = Theme.of(context).colorScheme;
    return AppBar(
      title: widget.title,
      actions: widget.actions == null
          ? null
          : [...widget.actions!, const SizedBox(width: Space.xs)],
      leading: widget.leading,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      // SizedBox.expand : sans enfant, le fond prendrait une hauteur nulle.
      flexibleSpace: SizedBox.expand(
        child: AnimatedOpacity(
          opacity: _scrolledUnder ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: g.blur, sigmaY: g.blur),
                  child: const SizedBox.expand(),
                ),
                // Teinte posée à part : même si le flou n'est pas rendu
                // (certains GPU), le texte du dessous reste masqué.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: g.bar,
                    border: Border(
                      bottom: BorderSide(
                          color: c.outlineVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Squelette commun des pages : fond ambiant, barre en verre sous laquelle
/// le contenu défile.
///
/// Le contenu reçoit dans `MediaQuery.padding.top` la hauteur de la barre :
/// utiliser [AppScaffold.pagePadding] pour les listes.
class AppScaffold extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showAppBar;

  /// Barre d'action fixée en bas (bouton principal d'un écran de saisie).
  final Widget? bottomBar;

  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    this.leading,
    required this.body,
    this.floatingActionButton,
    this.showAppBar = true,
    this.bottomBar,
  });

  /// Marges d'une page défilante : barre d'état + barre en verre en haut,
  /// encoche en bas. Calculées depuis la fenêtre : le résultat est le même
  /// que [context] soit au-dessus du Scaffold ou dans son corps (où
  /// `MediaQuery.padding` inclut déjà la barre).
  static EdgeInsets pagePadding(BuildContext context,
      {double top = Space.s, double bottom = Space.xxl, bool appBar = true}) {
    final pad = MediaQueryData.fromView(View.of(context)).padding;
    return EdgeInsets.fromLTRB(
        Space.page,
        pad.top + (appBar ? kToolbarHeight : 0) + top,
        Space.page,
        pad.bottom + bottom);
  }

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: showAppBar
            ? GlassAppBar(title: title, actions: actions, leading: leading)
            : null,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomBar == null
            ? null
            : ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: Glass.of(context).blur,
                      sigmaY: Glass.of(context).blur),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Glass.of(context).bar,
                      border: Border(
                          top: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.5))),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            Space.page, Space.m, Space.page, Space.m),
                        child: bottomBar,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Ouvre une feuille modale en verre (poignée, marges, clavier).
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool expand = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final g = Glass.of(sheetContext);
      final c = Theme.of(sheetContext).colorScheme;
      final radius =
          const BorderRadius.vertical(top: Radius.circular(Radii.sheet));
      return Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: g.blur, sigmaY: g.blur),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: g.fillStrong,
                borderRadius: radius,
                border: Border(top: BorderSide(color: g.border)),
              ),
              // Matériau transparent : les ListTile du contenu y dessinent
              // leurs effets d'appui (sinon masqués par le fond).
              child: Material(
                type: MaterialType.transparency,
                child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(
                            top: Space.m, bottom: Space.s),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: c.onSurfaceVariant.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Flexible(
                      fit: expand ? FlexFit.tight : FlexFit.loose,
                      child: builder(sheetContext),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
