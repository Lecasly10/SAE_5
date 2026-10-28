import 'dart:typed_data';

import '../models/recognition.dart';
import '../models/scanned_car.dart';
import 'api.dart';

class CarService {
  static final Map<String, Uint8List> _imageCache = {};
  static List<Recognition>? _catalog;

  /// [carId] : voiture choisie par l'utilisateur quand l'IA s'est trompée.
  static Future<ScannedCar> upload(Uint8List bytes, {String? carId}) async {
    final json = await Api.json(
      'POST',
      '/cars',
      body: {...Api.imageBody(bytes), if (carId != null) 'carId': carId},
      expect: 201,
    );
    final car = ScannedCar.fromJson(json as Map<String, dynamic>);
    _imageCache[car.id] = bytes;
    return car;
  }

  static Future<ScanResult> recognize(Uint8List bytes) async {
    final json = await Api.json('POST', '/predict', body: Api.imageBody(bytes));
    return ScanResult.fromJson(json as Map<String, dynamic>);
  }

  /// Toutes les voitures que l'IA connaît, pour choisir la bonne à la main.
  static Future<List<Recognition>> catalog() async {
    return _catalog ??= ((await Api.json('GET', '/catalog')) as List)
        .map((json) => Recognition.fromJson(
            {...json as Map<String, dynamic>, 'confidence': 0}))
        .toList();
  }

  /// Envoie une photo dont l'utilisateur a confirmé la voiture : elle servira
  /// au prochain entraînement de l'IA.
  static Future<void> sendTrainingPhoto(Uint8List bytes, String carId) {
    return Api.send(
      'POST',
      '/training-photos',
      body: {...Api.imageBody(bytes), 'carId': carId},
      expect: 201,
    );
  }

  static Future<List<ScannedCar>> list() async {
    return ((await Api.json('GET', '/cars')) as List)
        .map((json) => ScannedCar.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<Uint8List> image(String id) async {
    return _imageCache[id] ??=
        (await Api.send('GET', '/cars/$id/image')).bodyBytes;
  }

  static Future<void> delete(String id) async {
    await Api.send('DELETE', '/cars/$id', expect: 204);
    _imageCache.remove(id);
  }

  static void clearCache() => _imageCache.clear();
}
