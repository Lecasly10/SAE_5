import 'dart:typed_data';

/// Sur téléphone, image_picker réduit déjà la photo en gardant sa position.
Future<Uint8List> shrinkPhoto(Uint8List bytes) async => bytes;
