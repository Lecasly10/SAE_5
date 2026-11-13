import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import '../models/scanned_car.dart';
import 'api.dart';

class ShareService {
  static String textFor(ScannedCar car) {
    final recognition = car.recognition;
    final name = '${recognition.brand} ${recognition.model}'.trim();
    return "J'ai repéré une $name (${car.rarity.label}) avec Spot'It !";
  }

  /// Partage la photo d'une voiture avec un petit texte, par message ou
  /// réseau social. Faux si l'appareil ne sait pas partager.
  static Future<bool> shareCar(ScannedCar car, Uint8List bytes) async {
    final type = Api.imageType(bytes);
    final result = await SharePlus.instance.share(
      ShareParams(
        text: textFor(car),
        files: [
          XFile.fromData(
            bytes,
            mimeType: type,
            name: 'spotit.${type.split('/').last}',
          ),
        ],
      ),
    );
    return result.status != ShareResultStatus.unavailable;
  }
}
