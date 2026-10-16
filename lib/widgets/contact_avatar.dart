import 'dart:io';

import 'package:flutter/material.dart';

import 'ui/components.dart';

/// Photo du contact si elle existe sur l'appareil, sinon son initiale.
class ContactAvatar extends StatelessWidget {
  final String name;
  final String? imagePath;
  final double size;

  const ContactAvatar(
      {super.key, required this.name, this.imagePath, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final fallback = InitialsAvatar(name: name, size: size);
    final path = imagePath;
    if (path == null || path.isEmpty) return fallback;
    return ClipOval(
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        gaplessPlayback: true,
        // Fichier supprimé par le système : on retombe sur l'initiale.
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
