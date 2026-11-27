import 'dart:async';
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'photo_exif.dart';

const _maxSide = 1600;
const _quality = 0.85;

/// Photo réduite à 1600 px de côté au plus, avec sa position GPS. Celles des
/// téléphones récents dépassent 15 Mo, trop lourdes pour le serveur.
Future<Uint8List> shrinkPhoto(Uint8List bytes) async {
  final web.ImageBitmap bitmap;
  try {
    bitmap = await web.window
        .createImageBitmap(web.Blob(<web.BlobPart>[bytes.toJS].toJS))
        .toDart;
  } catch (_) {
    // Format que le navigateur ne sait pas lire : le serveur dira pourquoi
    return bytes;
  }

  final scale = _maxSide / max(bitmap.width, bitmap.height);
  if (scale >= 1) {
    bitmap.close();
    return bytes;
  }
  final canvas = web.HTMLCanvasElement()
    ..width = (bitmap.width * scale).round()
    ..height = (bitmap.height * scale).round();
  (canvas.getContext('2d') as web.CanvasRenderingContext2D)
    ..imageSmoothingQuality = 'high'
    ..drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close();

  final blob = Completer<web.Blob?>();
  canvas.toBlob(
      ((web.Blob? result) => blob.complete(result)).toJS,
      'image/jpeg',
      _quality.toJS);
  final small = await blob.future;
  if (small == null) return bytes;
  final jpeg = (await small.arrayBuffer().toDart).toDart.asUint8List();

  final exif = exifBlock(bytes);
  return exif == null ? jpeg : withExif(jpeg, exif);
}
