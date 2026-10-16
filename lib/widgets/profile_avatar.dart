import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/photo_service.dart';

/// Avatar rond : photo de profil si elle existe et est visible, sinon
/// l'initiale du nom sur un dégradé (aspect historique de l'app).
class ProfileAvatar extends StatelessWidget {
  final String? uid;
  final String name;
  final double size;

  /// false : ne pas tenter de charger la photo (pas de photo ou pas
  /// partagée), ce qui évite une requête inutile.
  final bool showPhoto;
  final List<Color> gradient;
  final Color initialColor;

  const ProfileAvatar({
    super.key,
    required this.uid,
    required this.name,
    this.size = 56,
    this.showPhoto = true,
    this.gradient = const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    this.initialColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: gradient),
      ),
      alignment: Alignment.center,
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: TextStyle(
          color: initialColor,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    final id = uid;
    if (!showPhoto || id == null) return fallback;
    return FutureBuilder<Uint8List?>(
      future: PhotoService().bytesFor(id),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) return fallback;
        return ClipOval(
          child: Image.memory(bytes,
              width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
        );
      },
    );
  }
}
