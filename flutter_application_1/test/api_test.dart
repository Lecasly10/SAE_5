import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spot_it/services/api.dart';

void main() {
  Uint8List bytes(List<int> values) => Uint8List.fromList(values);

  test('le type de la photo vient de son contenu, pas de son nom', () {
    expect(Api.imageType(bytes([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a])),
        'image/png');
    expect(
        Api.imageType(bytes(ascii.encode('RIFF1234WEBPVP8 '))), 'image/webp');
    expect(Api.imageType(bytes([0xff, 0xd8, 0xff, 0xe0])), 'image/jpeg');
    expect(Api.imageType(bytes(ascii.encode('RIFF'))), 'image/jpeg');
  });

  test("le corps d'une photo est en base64 avec son type", () {
    final body = Api.imageBody(bytes([0xff, 0xd8, 0xff]));

    expect(body, {'image': '/9j/', 'contentType': 'image/jpeg'});
  });

  test("le message d'erreur n'affiche pas « Exception: »", () {
    expect(
        errorMessage(Exception('Serveur injoignable')), 'Serveur injoignable');
  });
}
