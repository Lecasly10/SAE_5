import 'package:geolocator/geolocator.dart';

import '../models/scanned_car.dart';

/// Position du téléphone, pour placer sur la carte une photo qui n'a pas
/// d'informations de lieu.
class LocationService {
  /// Null si le téléphone ne sait pas où il est ou si l'utilisateur refuse.
  /// Ne bloque jamais l'ajout plus de quelques secondes, même si le
  /// navigateur attend une réponse à sa demande d'autorisation.
  static Future<CarLocation?> current() =>
      _current().timeout(const Duration(seconds: 10), onTimeout: () => null);

  static Future<CarLocation?> _current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 8),
        ),
      );
      return CarLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        fromPhoto: false,
      );
    } catch (_) {
      // Position introuvable : la voiture est ajoutée sans endroit
      return null;
    }
  }
}
