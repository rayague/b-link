import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Partage l'image du widget sous [boundaryKey] (un RepaintBoundary), avec
/// un texte d'accompagnement, via les applications du téléphone.
Future<void> shareWidgetImage(
  GlobalKey boundaryKey, {
  required String fileName,
  String? text,
  double pixelRatio = 3,
}) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(png!.buffer.asUint8List());
  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path, mimeType: 'image/png')],
    text: text,
  ));
}
