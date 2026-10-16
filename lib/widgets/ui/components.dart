import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'glass.dart';

/// Ton d'un élément : action (ardoise), accent (or), danger, neutre.
enum Tone { primary, accent, danger, neutral }

extension ToneColor on Tone {
  Color color(ColorScheme c) => switch (this) {
        Tone.primary => c.primary,
        Tone.accent => c.secondary,
        Tone.danger => c.error,
        Tone.neutral => c.onSurfaceVariant,
      };
}

/// Pastille carrée arrondie portant une icône, en aplat très léger.
/// Remplace les dégradés de couleur des anciens écrans.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final double size;

  const IconBadge(this.icon,
      {super.key, this.tone = Tone.primary, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = tone.color(Theme.of(context).colorScheme);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Titre de section, avec une action facultative à droite.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(this.title,
      {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(
          left: Space.xs, top: Space.xl, bottom: Space.s),
      child: Row(
        children: [
          Expanded(child: Text(title, style: t.titleMedium)),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Petite étiquette arrondie (jours restants, relation, statut).
class Pill extends StatelessWidget {
  final String label;
  final Tone tone;
  final IconData? icon;
  final bool strong;

  const Pill(this.label,
      {super.key, this.tone = Tone.neutral, this.icon, this.strong = false});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final color = tone.color(c);
    final fg = strong
        ? (tone == Tone.accent ? c.onSecondary : c.onPrimary)
        : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: strong ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: Space.xs),
          ],
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Avatar à initiale, teinte sourde et stable déduite du nom (la même
/// personne garde toujours la même couleur, lisible en clair et en sombre).
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;

  const InitialsAvatar({super.key, required this.name, this.size = 44});

  /// Teinte (0–360) stable : somme pondérée des caractères, indépendante de
  /// `String.hashCode` (non garanti entre deux exécutions).
  static double hueFor(String name) {
    var h = 0;
    for (final unit in name.trim().toLowerCase().codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return (h % 360).toDouble();
  }

  static String initialOf(String name) {
    final t = name.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hue = hueFor(name);
    final ink = HSLColor.fromAHSL(1, hue, 0.30, dark ? 0.78 : 0.38).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ink.withValues(alpha: dark ? 0.16 : 0.13),
        border: Border.all(color: ink.withValues(alpha: 0.18)),
      ),
      child: Text(
        initialOf(name),
        style: TextStyle(
          color: ink,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

/// Champ « sélecteur » (date, heure, pays) au même dessin que les champs
/// texte : libellé, icône, valeur ou invite.
class PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String? placeholder;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? leading;

  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.placeholder,
    this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.control),
      child: InputDecorator(
        isEmpty: value == null && placeholder == null,
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          prefixIcon: leading == null
              ? Icon(icon)
              : Padding(
                  padding: const EdgeInsets.only(left: Space.m, right: Space.s),
                  child: leading),
          prefixIconConstraints: leading == null
              ? null
              : const BoxConstraints(minWidth: 40, minHeight: 24),
          suffixIcon: enabled ? const Icon(Icons.expand_more_rounded) : null,
        ),
        child: Text(
          value ?? placeholder ?? '',
          style: t.bodyLarge?.copyWith(
            color: value == null || !enabled ? c.onSurfaceVariant : c.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Ligne d'information en lecture seule : icône, libellé, valeur.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow(
      {super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.onSurfaceVariant),
          const SizedBox(width: Space.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: t.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne d'action dans une carte : icône, titre, sous-titre, chevron.
class ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Tone tone;
  final Widget? trailing;

  const ActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.tone = Tone.primary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.control),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: Space.xs, vertical: Space.s),
        child: Row(
          children: [
            IconBadge(icon, tone: tone, size: 36),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: t.bodyLarge?.copyWith(
                          color: tone == Tone.danger ? c.error : null,
                          fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: t.bodySmall),
                  ],
                ],
              ),
            ),
            trailing ??
                (onTap == null
                    ? const SizedBox.shrink()
                    : Icon(Icons.chevron_right_rounded,
                        color: c.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// État vide : icône, titre, explication, action facultative.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.xxl, vertical: Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon, tone: Tone.neutral, size: 64),
          const SizedBox(height: Space.l),
          Text(title, style: t.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: Space.s),
            Text(message!,
                style: t.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: Space.xl),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Bandeau d'information discret dans une carte (modération, conseil…).
class NoticeCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Tone tone;

  const NoticeCard(
      {super.key, required this.icon, required this.text, this.tone = Tone.primary});

  @override
  Widget build(BuildContext context) {
    final color = tone.color(Theme.of(context).colorScheme);
    return GlassCard(
      tint: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: Space.m),
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Séparateur fin entre les lignes d'une carte.
class CardDivider extends StatelessWidget {
  const CardDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: Space.s, indent: 52);
}
