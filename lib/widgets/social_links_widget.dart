import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'ui/components.dart';

/// Liens vers les réseaux sociaux : une ligne par lien, sobre (icône
/// neutre, nom du réseau, adresse). [onRemove] ajoute un bouton de
/// suppression (mode édition du profil).
class SocialLinksWidget extends StatelessWidget {
  final Map<String, String> socialLinks;
  final ValueChanged<String>? onRemove;

  const SocialLinksWidget({super.key, required this.socialLinks, this.onRemove});

  /// Réseaux proposés à l'ajout (clé enregistrée en minuscules).
  static const platforms = [
    'instagram',
    'facebook',
    'tiktok',
    'x',
    'linkedin',
    'youtube',
    'snapchat',
    'whatsapp',
    'telegram',
    'github',
    'discord',
    'twitch',
    'spotify',
    'pinterest',
    'reddit',
  ];

  static IconData iconFor(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('facebook')) return Icons.facebook;
    if (p.contains('instagram')) return Icons.camera_alt_outlined;
    if (p == 'x' || p.contains('twitter') || p.contains('x.com')) {
      return Icons.alternate_email_rounded;
    }
    if (p.contains('linkedin')) return Icons.work_outline_rounded;
    if (p.contains('youtube')) return Icons.play_circle_outline_rounded;
    if (p.contains('tiktok')) return Icons.music_note_outlined;
    if (p.contains('snapchat')) return Icons.chat_bubble_outline_rounded;
    if (p.contains('whatsapp')) return Icons.phone_outlined;
    if (p.contains('telegram')) return Icons.send_outlined;
    if (p.contains('github')) return Icons.code_rounded;
    if (p.contains('discord')) return Icons.forum_outlined;
    if (p.contains('reddit')) return Icons.reddit;
    if (p.contains('pinterest')) return Icons.push_pin_outlined;
    if (p.contains('twitch')) return Icons.videocam_outlined;
    if (p.contains('spotify')) return Icons.headphones_outlined;
    return Icons.link_rounded;
  }

  /// Réseau reconnu d'après l'adresse (« instagram.com/… » -> instagram),
  /// sinon le nom de domaine.
  static String platformFromUrl(String url) {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    final host = (uri?.host ?? '').replaceFirst(RegExp(r'^www\.'), '');
    if (host == 'x.com' || host == 'twitter.com') return 'x';
    for (final p in platforms) {
      if (host.startsWith('$p.') || host.contains('.$p.')) return p;
    }
    return host.isEmpty ? 'link' : host;
  }

  static String displayName(String platform, [String? url]) {
    const names = {
      'facebook': 'Facebook',
      'instagram': 'Instagram',
      'twitter': 'X (Twitter)',
      'x': 'X (Twitter)',
      'linkedin': 'LinkedIn',
      'youtube': 'YouTube',
      'tiktok': 'TikTok',
      'snapchat': 'Snapchat',
      'whatsapp': 'WhatsApp',
      'telegram': 'Telegram',
      'github': 'GitHub',
      'discord': 'Discord',
      'reddit': 'Reddit',
      'pinterest': 'Pinterest',
      'twitch': 'Twitch',
      'spotify': 'Spotify',
    };
    final known = names[platform.toLowerCase()];
    if (known != null) return known;
    // Anciennes clés génériques : on affiche le domaine du lien.
    if (url != null && (platform == 'primary' || platform == 'link')) {
      return platformFromUrl(url);
    }
    return platform;
  }

  static String _short(String url) {
    var s = url.replaceFirst(RegExp(r'^https?://'), '');
    s = s.replaceFirst(RegExp(r'^www\.'), '');
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  /// N'ouvre que des liens web (un lien saisi par un autre utilisateur ne
  /// doit pas pouvoir lancer autre chose qu'un navigateur).
  static Future<void> open(String url) async {
    final full = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';
    final uri = Uri.tryParse(full);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (socialLinks.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final entries = socialLinks.entries.toList();
    return Column(
      children: [
        for (final (i, e) in entries.indexed) ...[
          if (i > 0) const CardDivider(),
          InkWell(
            onTap: () => open(e.value),
            borderRadius: BorderRadius.circular(Radii.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.xs, vertical: Space.s),
              child: Row(
                children: [
                  IconBadge(iconFor(platformFromUrl(e.value)), tone: Tone.neutral, size: 36),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName(e.key, e.value),
                            style: t.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500)),
                        Text(_short(e.value),
                            style: t.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (onRemove != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: c.onSurfaceVariant,
                      onPressed: () => onRemove!(e.key),
                    )
                  else
                    Icon(Icons.north_east_rounded,
                        size: 18, color: c.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
