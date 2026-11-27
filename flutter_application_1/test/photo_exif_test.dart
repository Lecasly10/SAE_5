import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spot_it/services/photo_exif.dart';

void main() {
  // Segment JPEG : FF, marqueur, taille sur 2 octets (elle compte ses 2 octets)
  List<int> segment(int marker, List<int> content) => [
        0xff,
        marker,
        (content.length + 2) >> 8,
        (content.length + 2) & 0xff,
        ...content,
      ];

  // Bloc EXIF avec une seule entrée : l'orientation (6 = tournée de 90°)
  List<int> exif({required bool little}) {
    List<int> u16(int value) =>
        little ? [value & 0xff, value >> 8] : [value >> 8, value & 0xff];
    List<int> u32(int value) =>
        little ? [value & 0xff, 0, 0, 0] : [0, 0, 0, value & 0xff];
    return segment(0xe1, [
      ...ascii.encode('Exif'),
      0,
      0,
      ...ascii.encode(little ? 'II' : 'MM'),
      ...u16(42),
      ...u32(8),
      ...u16(1),
      ...u16(0x0112),
      ...u16(3),
      ...u32(1),
      ...u16(6),
      0,
      0,
      ...u32(0),
    ]);
  }

  Uint8List jpeg(List<int> segments) => Uint8List.fromList([
        0xff,
        0xd8,
        ...segment(0xe0, ascii.encode('JFIF')),
        ...segments,
        ...segment(0xda, [1, 2, 3]),
      ]);

  test('le bloc EXIF est retrouvé dans la photo', () {
    final block = exif(little: true);

    expect(exifBlock(jpeg(block)), block);
  });

  test('pas de bloc EXIF pour une photo sans métadonnées ou pas en JPEG', () {
    expect(exifBlock(jpeg([])), isNull);
    expect(exifBlock(Uint8List.fromList([0x89, 0x50, 0x4e, 0x47])), isNull);
  });

  test("le bloc est remis au début et l'orientation passe à droite", () {
    for (final little in [true, false]) {
      final small = jpeg([]);
      final result = withExif(small, Uint8List.fromList(exif(little: little)));
      final block = exifBlock(result)!;

      expect(result.sublist(0, 2), [0xff, 0xd8]);
      expect(result.length, small.length + block.length);
      // Valeur de l'orientation : octets 28 et 29 du bloc (première entrée)
      final value = ByteData.sublistView(block)
          .getUint16(28, little ? Endian.little : Endian.big);
      expect(value, 1);
    }
  });
}
