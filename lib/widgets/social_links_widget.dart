import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLinksWidget extends StatelessWidget {
  final Map<String, String> socialLinks;
  final bool isCompact;
  final double iconSize;

  const SocialLinksWidget({
    super.key,
    required this.socialLinks,
    this.isCompact = false,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (socialLinks.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: socialLinks.entries.map((entry) {
          return _buildSocialIcon(entry.key, entry.value, isDark,
              compact: true);
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: socialLinks.entries.map((entry) {
        return _buildSocialButton(entry.key, entry.value, isDark);
      }).toList(),
    );
  }

  Widget _buildSocialIcon(String platform, String url, bool isDark,
      {bool compact = false}) {
    final iconData = _getSocialIcon(platform);
    final colors = _getSocialColors(platform);

    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: compact ? 40 : 48,
        height: compact ? 40 : 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          iconData,
          color: Colors.white,
          size: compact ? 20 : 24,
        ),
      ),
    );
  }

  Widget _buildSocialButton(String platform, String url, bool isDark) {
    final iconData = _getSocialIcon(platform);
    final colors = _getSocialColors(platform);
    final displayName = _getSocialDisplayName(platform);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors[0].withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatUrl(url),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSocialIcon(String platform) {
    final lower = platform.toLowerCase();
    if (lower.contains('facebook')) return Icons.facebook;
    if (lower.contains('instagram')) return Icons.camera_alt;
    if (lower.contains('twitter') || lower.contains('x.com'))
      return Icons.alternate_email;
    if (lower.contains('linkedin')) return Icons.business;
    if (lower.contains('youtube')) return Icons.play_arrow;
    if (lower.contains('tiktok')) return Icons.music_note;
    if (lower.contains('snapchat')) return Icons.camera;
    if (lower.contains('whatsapp')) return Icons.phone;
    if (lower.contains('telegram')) return Icons.send;
    if (lower.contains('github')) return Icons.code;
    if (lower.contains('discord')) return Icons.forum;
    if (lower.contains('reddit')) return Icons.reddit;
    if (lower.contains('pinterest')) return Icons.push_pin;
    if (lower.contains('twitch')) return Icons.videocam;
    if (lower.contains('spotify')) return Icons.music_video;
    return Icons.link;
  }

  List<Color> _getSocialColors(String platform) {
    final lower = platform.toLowerCase();
    if (lower.contains('facebook'))
      return [const Color(0xFF1877F2), const Color(0xFF42A5F5)];
    if (lower.contains('instagram'))
      return [const Color(0xFFE4405F), const Color(0xFFFCAF45)];
    if (lower.contains('twitter') || lower.contains('x.com'))
      return [const Color(0xFF1DA1F2), const Color(0xFF42A5F5)];
    if (lower.contains('linkedin'))
      return [const Color(0xFF0A66C2), const Color(0xFF42A5F5)];
    if (lower.contains('youtube'))
      return [const Color(0xFFFF0000), const Color(0xFFE57373)];
    if (lower.contains('tiktok'))
      return [const Color(0xFF000000), const Color(0xFF69C9D0)];
    if (lower.contains('snapchat'))
      return [const Color(0xFFFFFC00), const Color(0xFFFDD835)];
    if (lower.contains('whatsapp'))
      return [const Color(0xFF25D366), const Color(0xFF66BB6A)];
    if (lower.contains('telegram'))
      return [const Color(0xFF0088CC), const Color(0xFF42A5F5)];
    if (lower.contains('github'))
      return [const Color(0xFF181717), const Color(0xFF424242)];
    if (lower.contains('discord'))
      return [const Color(0xFF5865F2), const Color(0xFF7289DA)];
    if (lower.contains('reddit'))
      return [const Color(0xFFFF4500), const Color(0xFFFF6B35)];
    if (lower.contains('pinterest'))
      return [const Color(0xFFE60023), const Color(0xFFE57373)];
    if (lower.contains('twitch'))
      return [const Color(0xFF9146FF), const Color(0xFFAB47BC)];
    if (lower.contains('spotify'))
      return [const Color(0xFF1DB954), const Color(0xFF66BB6A)];
    return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)];
  }

  String _getSocialDisplayName(String platform) {
    final lower = platform.toLowerCase();
    if (lower.contains('facebook')) return 'Facebook';
    if (lower.contains('instagram')) return 'Instagram';
    if (lower.contains('twitter')) return 'Twitter';
    if (lower.contains('x.com')) return 'X (Twitter)';
    if (lower.contains('linkedin')) return 'LinkedIn';
    if (lower.contains('youtube')) return 'YouTube';
    if (lower.contains('tiktok')) return 'TikTok';
    if (lower.contains('snapchat')) return 'Snapchat';
    if (lower.contains('whatsapp')) return 'WhatsApp';
    if (lower.contains('telegram')) return 'Telegram';
    if (lower.contains('github')) return 'GitHub';
    if (lower.contains('discord')) return 'Discord';
    if (lower.contains('reddit')) return 'Reddit';
    if (lower.contains('pinterest')) return 'Pinterest';
    if (lower.contains('twitch')) return 'Twitch';
    if (lower.contains('spotify')) return 'Spotify';
    return platform;
  }

  String _formatUrl(String url) {
    String formatted = url;
    if (formatted.startsWith('http://')) {
      formatted = formatted.substring(7);
    } else if (formatted.startsWith('https://')) {
      formatted = formatted.substring(8);
    }
    if (formatted.startsWith('www.')) {
      formatted = formatted.substring(4);
    }
    if (formatted.length > 40) {
      formatted = '${formatted.substring(0, 40)}...';
    }
    return formatted;
  }

  Future<void> _launchUrl(String url) async {
    String fullUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      fullUrl = 'https://$url';
    }

    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
