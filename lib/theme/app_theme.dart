import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Système de design de B-Link : sobre, verre dépoli, couleurs du logo
/// (ardoise nuit + crème dorée).
///
/// Règles :
/// - espacements sur une grille de 4 ([Space]) ;
/// - trois rayons seulement ([Radii]) ;
/// - une couleur d'action (primary, ardoise) et un accent rare (secondary,
///   or) réservé aux anniversaires du jour et aux mises en avant ;
/// - aucune couleur en dur dans les écrans : tout passe par le thème,
///   [Glass] et le [ColorScheme].

/// Espacements (grille de 4).
abstract final class Space {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Marge horizontale des pages.
  static const double page = 20;
}

/// Rayons d'arrondi.
abstract final class Radii {
  /// Champs, boutons, puces.
  static const double control = 14;

  /// Cartes et tuiles.
  static const double card = 22;

  /// Feuilles et dialogues.
  static const double sheet = 28;
}

/// Couleurs de marque, tirées de l'icône.
abstract final class Brand {
  static const ink = Color(0xFF181B28);
  static const slate = Color(0xFF3E4569);
  static const slateSoft = Color(0xFFB8BFE3);
  static const gold = Color(0xFF9C7424);
  static const goldSoft = Color(0xFFE8CD86);
}

/// Jetons du verre dépoli, différents en clair et en sombre.
@immutable
class Glass extends ThemeExtension<Glass> {
  /// Remplissage translucide des surfaces.
  final Color fill;

  /// Remplissage plus opaque (feuilles, barres) pour la lisibilité.
  final Color fillStrong;

  /// Liseré de 1 px qui dessine le bord du verre.
  final Color border;

  /// Reflet en haut à gauche des surfaces.
  final Color highlight;

  /// Fond de la page et halos colorés derrière le verre.
  final Color backdrop;
  final Color bloomA;
  final Color bloomB;

  /// Flou des surfaces qui recouvrent du contenu (barres, feuilles).
  final double blur;

  const Glass({
    required this.fill,
    required this.fillStrong,
    required this.border,
    required this.highlight,
    required this.backdrop,
    required this.bloomA,
    required this.bloomB,
    this.blur = 24,
  });

  static const light = Glass(
    fill: Color(0x9EFFFFFF), // 62 %
    fillStrong: Color(0xDBFAFAF8), // 86 %
    border: Color(0xBFFFFFFF),
    highlight: Color(0x66FFFFFF),
    backdrop: Color(0xFFF2F1EC),
    bloomA: Color(0x383E4569), // ardoise 22 %
    bloomB: Color(0x40E8CD86), // or 25 %
  );

  static const dark = Glass(
    fill: Color(0x12FFFFFF), // 7 %
    fillStrong: Color(0xD9171A26),
    border: Color(0x1FFFFFFF),
    highlight: Color(0x0FFFFFFF),
    backdrop: Color(0xFF0E1018),
    bloomA: Color(0x803E4569),
    bloomB: Color(0x1FE8CD86),
  );

  static Glass of(BuildContext context) =>
      Theme.of(context).extension<Glass>() ?? light;

  @override
  Glass copyWith({
    Color? fill,
    Color? fillStrong,
    Color? border,
    Color? highlight,
    Color? backdrop,
    Color? bloomA,
    Color? bloomB,
    double? blur,
  }) =>
      Glass(
        fill: fill ?? this.fill,
        fillStrong: fillStrong ?? this.fillStrong,
        border: border ?? this.border,
        highlight: highlight ?? this.highlight,
        backdrop: backdrop ?? this.backdrop,
        bloomA: bloomA ?? this.bloomA,
        bloomB: bloomB ?? this.bloomB,
        blur: blur ?? this.blur,
      );

  @override
  Glass lerp(Glass? other, double t) {
    if (other == null) return this;
    return Glass(
      fill: Color.lerp(fill, other.fill, t)!,
      fillStrong: Color.lerp(fillStrong, other.fillStrong, t)!,
      border: Color.lerp(border, other.border, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      backdrop: Color.lerp(backdrop, other.backdrop, t)!,
      bloomA: Color.lerp(bloomA, other.bloomA, t)!,
      bloomB: Color.lerp(bloomB, other.bloomB, t)!,
      blur: blur + (other.blur - blur) * t,
    );
  }
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ColorScheme _scheme(Brightness b) {
    final base = ColorScheme.fromSeed(seedColor: Brand.slate, brightness: b);
    if (b == Brightness.light) {
      return base.copyWith(
        primary: Brand.slate,
        onPrimary: Colors.white,
        secondary: Brand.gold,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFF3E6C4),
        onSecondaryContainer: const Color(0xFF3A2C0A),
        surface: const Color(0xFFF7F6F2),
        onSurface: Brand.ink,
        onSurfaceVariant: const Color(0xFF5C6074),
        outline: const Color(0xFFB9BBC6),
        outlineVariant: const Color(0xFFDDDDE3),
      );
    }
    return base.copyWith(
      primary: Brand.slateSoft,
      onPrimary: Brand.ink,
      secondary: Brand.goldSoft,
      onSecondary: const Color(0xFF2A2006),
      secondaryContainer: const Color(0xFF473913),
      onSecondaryContainer: const Color(0xFFF3E6C4),
      surface: const Color(0xFF12141D),
      onSurface: const Color(0xFFE7E7EE),
      onSurfaceVariant: const Color(0xFFA2A5B7),
      outline: const Color(0xFF4A4E63),
      outlineVariant: const Color(0xFF2A2D3D),
    );
  }

  /// Échelle typographique (taille / interligne sur la grille de 4).
  static TextTheme _text(ColorScheme c) {
    final base = (c.brightness == Brightness.light
            ? Typography.material2021().black
            : Typography.material2021().white)
        .apply(bodyColor: c.onSurface, displayColor: c.onSurface);
    TextStyle s(TextStyle? t, double size, double height, FontWeight w,
            [double spacing = 0]) =>
        t!.copyWith(
            fontSize: size,
            height: height / size,
            fontWeight: w,
            letterSpacing: spacing);
    return base.copyWith(
      displaySmall: s(base.displaySmall, 32, 40, FontWeight.w600, -0.6),
      headlineMedium: s(base.headlineMedium, 28, 36, FontWeight.w600, -0.5),
      headlineSmall: s(base.headlineSmall, 24, 32, FontWeight.w600, -0.4),
      titleLarge: s(base.titleLarge, 20, 28, FontWeight.w600, -0.2),
      titleMedium: s(base.titleMedium, 16, 24, FontWeight.w600, -0.1),
      titleSmall: s(base.titleSmall, 14, 20, FontWeight.w600),
      bodyLarge: s(base.bodyLarge, 16, 24, FontWeight.w400),
      bodyMedium: s(base.bodyMedium, 14, 20, FontWeight.w400),
      bodySmall: s(base.bodySmall, 12, 16, FontWeight.w400, 0.1)
          .copyWith(color: c.onSurfaceVariant),
      labelLarge: s(base.labelLarge, 14, 20, FontWeight.w600, 0.1),
      labelMedium: s(base.labelMedium, 12, 16, FontWeight.w500, 0.2),
      labelSmall: s(base.labelSmall, 11, 16, FontWeight.w600, 0.6),
    );
  }

  static ThemeData _build(Brightness b) {
    final c = _scheme(b);
    final glass = b == Brightness.light ? Glass.light : Glass.dark;
    final text = _text(c);
    final control = BorderRadius.circular(Radii.control);
    OutlineInputBorder field(Color color, [double width = 1]) =>
        OutlineInputBorder(
            borderRadius: control,
            borderSide: BorderSide(color: color, width: width));

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: c,
      textTheme: text,
      extensions: [glass],
      scaffoldBackgroundColor: glass.backdrop,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: c.onSurface,
        titleTextStyle: text.titleMedium,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: glass.fill,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: glass.border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.l),
        iconColor: c.onSurfaceVariant,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: control),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glass.fill,
        isDense: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Space.l, vertical: 14),
        prefixIconColor: c.onSurfaceVariant,
        suffixIconColor: c.onSurfaceVariant,
        labelStyle: text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: c.primary),
        hintStyle: text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
        helperStyle: text.bodySmall,
        border: field(c.outlineVariant),
        enabledBorder: field(c.outlineVariant),
        disabledBorder: field(c.outlineVariant.withValues(alpha: 0.5)),
        focusedBorder: field(c.primary, 1.5),
        errorBorder: field(c.error),
        focusedErrorBorder: field(c.error, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          shape: RoundedRectangleBorder(borderRadius: control),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          shape: RoundedRectangleBorder(borderRadius: control),
          side: BorderSide(color: c.outline),
          foregroundColor: c.onSurface,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: control),
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: control),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: control),
        extendedTextStyle: text.labelLarge,
      ),
      // Puce choisie : teinte légère, liseré et texte en couleur d'action
      // (lisible en clair comme en sombre).
      chipTheme: ChipThemeData(
        backgroundColor: glass.fill,
        selectedColor: c.primary.withValues(alpha: 0.14),
        secondarySelectedColor: c.primary.withValues(alpha: 0.14),
        disabledColor: glass.fill,
        checkmarkColor: c.primary,
        labelStyle: WidgetStateTextStyle.resolveWith((s) =>
            text.labelLarge!.copyWith(
                color: s.contains(WidgetState.disabled)
                    ? c.onSurfaceVariant.withValues(alpha: 0.6)
                    : s.contains(WidgetState.selected)
                        ? c.primary
                        : c.onSurface)),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: c.primary),
        side: WidgetStateBorderSide.resolveWith((s) => BorderSide(
            color: s.contains(WidgetState.selected)
                ? c.primary.withValues(alpha: 0.6)
                : c.outlineVariant)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 6),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: glass.fill,
          selectedBackgroundColor: c.primary,
          selectedForegroundColor: c.onPrimary,
          foregroundColor: c.onSurface,
          side: BorderSide(color: c.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: control),
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 44),
        ),
        selectedIcon: const SizedBox.shrink(),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? Colors.transparent
                : c.outline),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        inactiveTrackColor: c.outlineVariant,
      ),
      dividerTheme: DividerThemeData(
        color: c.outlineVariant.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: glass.fillStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
          side: BorderSide(color: glass.border),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: glass.fillStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          side: BorderSide(color: glass.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: c.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.onInverseSurface),
        actionTextColor: c.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: control),
        insetPadding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: Colors.transparent,
        circularTrackColor: Colors.transparent,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: glass.fillStrong,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sheet)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: glass.fillStrong,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sheet)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
