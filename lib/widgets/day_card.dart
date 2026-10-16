import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Carte « Mon jour » exportée en image (1080 × 1350 à pixelRatio 3).
/// Toujours aux couleurs de la marque, quel que soit le thème de l'app.
class DayCard extends StatelessWidget {
  final String eyebrow;
  final String date;
  final String headline;
  final String? detail;
  final String footer;
  final String link;

  const DayCard({
    super.key,
    required this.eyebrow,
    required this.date,
    required this.headline,
    this.detail,
    required this.footer,
    required this.link,
  });

  static const _cream = Color(0xFFF4EBD3);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 450,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF262B45), Brand.ink],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -120,
              top: -90,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Brand.goldSoft.withValues(alpha: 0.28),
                    Brand.goldSoft.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: DefaultTextStyle(
                style: const TextStyle(color: _cream, fontFamily: 'Roboto'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/icon/app_icon.png',
                              width: 28, height: 28),
                        ),
                        const SizedBox(width: 10),
                        const Text('B-Link',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Spacer(),
                    Text(eyebrow.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w600,
                            color: Brand.goldSoft.withValues(alpha: 0.9))),
                    const SizedBox(height: 6),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 48,
                            height: 1.05,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.2)),
                    const SizedBox(height: 18),
                    Text(headline,
                        style: const TextStyle(fontSize: 18, height: 1.35)),
                    if (detail != null) ...[
                      const SizedBox(height: 8),
                      Text(detail!,
                          style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: _cream.withValues(alpha: 0.7))),
                    ],
                    const Spacer(),
                    Container(
                      height: 1,
                      color: _cream.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 14),
                    Text(footer,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(link,
                        style: TextStyle(
                            fontSize: 12, color: _cream.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
