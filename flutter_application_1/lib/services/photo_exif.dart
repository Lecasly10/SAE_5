import 'dart:typed_data';

const _startOfScan = 0xda;
const _app1 = 0xe1;
const _orientationTag = 0x0112;
// FF E1, la taille sur 2 octets puis « Exif\0\0 » : le TIFF commence après
const _tiffStart = 10;

/// Bloc EXIF d'une photo JPEG (position GPS, date, appareil), ou null si elle
/// n'en a pas. Le navigateur l'efface quand il réduit la photo.
Uint8List? exifBlock(Uint8List jpeg) {
  if (jpeg.length < 4 || jpeg[0] != 0xff || jpeg[1] != 0xd8) return null;
  var offset = 2;
  while (offset + 4 <= jpeg.length && jpeg[offset] == 0xff) {
    final marker = jpeg[offset + 1];
    // Après ce marqueur viennent les pixels, plus aucune information
    if (marker == _startOfScan) return null;
    final end = offset + 2 + (jpeg[offset + 2] << 8 | jpeg[offset + 3]);
    if (end > jpeg.length) return null;
    if (marker == _app1 && _isExif(jpeg, offset + 4)) {
      return Uint8List.sublistView(jpeg, offset, end);
    }
    offset = end;
  }
  return null;
}

/// La photo JPEG avec le bloc EXIF remis juste après son début.
Uint8List withExif(Uint8List jpeg, Uint8List exif) {
  final upright = Uint8List.fromList(exif);
  _markUpright(upright);
  return Uint8List.fromList(
      [...jpeg.sublist(0, 2), ...upright, ...jpeg.sublist(2)]);
}

bool _isExif(Uint8List bytes, int offset) =>
    offset + 6 <= bytes.length &&
    String.fromCharCodes(bytes.sublist(offset, offset + 6)) == 'Exif\x00\x00';

// Le navigateur a déjà redressé la photo en la redessinant : sans ça, l'IA la
// tournerait une deuxième fois en lisant l'orientation.
void _markUpright(Uint8List exif) {
  if (exif.length < _tiffStart + 8) return;
  final data = ByteData.sublistView(exif);
  final endian = exif[_tiffStart] == 0x49 ? Endian.little : Endian.big;
  final ifd = _tiffStart + data.getUint32(_tiffStart + 4, endian);
  if (ifd + 2 > exif.length) return;

  // Chaque entrée fait 12 octets : numéro, type, nombre, valeur
  for (var index = 0; index < data.getUint16(ifd, endian); index += 1) {
    final entry = ifd + 2 + index * 12;
    if (entry + 12 > exif.length) return;
    if (data.getUint16(entry, endian) == _orientationTag) {
      data.setUint16(entry + 8, 1, endian);
      return;
    }
  }
}
