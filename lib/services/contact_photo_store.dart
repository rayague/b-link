import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Photos des contacts, gardées dans le dossier de l'application.
///
/// image_picker renvoie un fichier de cache que le système peut effacer à
/// tout moment : la photo disparaissait alors de la fiche. On en garde donc
/// une copie à nous.
class ContactPhotoStore {
  static const _folder = 'contact_photos';

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _folder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Ouvre la galerie et renvoie le chemin de la copie, ou null si annulé.
  Future<String?> pick() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return null;
    final dir = await _dir();
    final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final target = p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}$ext');
    await File(picked.path).copy(target);
    return target;
  }

  /// Supprime une photo si elle nous appartient (rien sinon).
  Future<void> delete(String? path) async {
    if (path == null || !path.contains('${Platform.pathSeparator}$_folder')) {
      return;
    }
    try {
      await File(path).delete();
    } catch (_) {}
  }

  /// Efface toutes les photos (déconnexion, suppression du compte).
  Future<void> clear() async {
    try {
      final dir = await _dir();
      await dir.delete(recursive: true);
    } catch (_) {}
  }
}
