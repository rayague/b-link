import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/photo_service.dart';
import 'ui/components.dart';

/// Avatar rond d'un profil : sa photo si elle existe et est visible, sinon
/// son initiale.
class ProfileAvatar extends StatefulWidget {
  final String? uid;
  final String name;
  final double size;

  /// false : ne pas tenter de charger la photo (pas de photo ou pas
  /// partagée), ce qui évite une requête inutile.
  final bool showPhoto;

  const ProfileAvatar({
    super.key,
    required this.uid,
    required this.name,
    this.size = 44,
    this.showPhoto = true,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Future<Uint8List?>? _bytes;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(ProfileAvatar old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid || old.showPhoto != widget.showPhoto) _resolve();
  }

  /// Une seule requête par avatar (et non à chaque reconstruction, ce qui
  /// faisait clignoter l'initiale entre deux images).
  void _resolve() {
    final id = widget.uid;
    _bytes = widget.showPhoto && id != null ? PhotoService().bytesFor(id) : null;
  }

  @override
  Widget build(BuildContext context) {
    final fallback = InitialsAvatar(name: widget.name, size: widget.size);
    final future = _bytes;
    if (future == null) return fallback;
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) return fallback;
        return ClipOval(
          child: Image.memory(bytes,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              gaplessPlayback: true),
        );
      },
    );
  }
}
