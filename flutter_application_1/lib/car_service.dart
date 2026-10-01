import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'auth_service.dart';
import 'scanned_car.dart';

class CarService {
  static const String _baseUrl = '${AuthService.host}/api/cars';

  static final Map<String, Uint8List> _imageCache = {};

  static Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer ${AuthService.token}',
      };

  static Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on http.ClientException {
      throw Exception('Serveur injoignable. Vérifiez votre connexion.');
    }
  }

  static String _errorOf(http.Response res) {
    try {
      return jsonDecode(res.body)['error'] as String;
    } catch (_) {
      return 'Erreur du serveur (${res.statusCode})';
    }
  }

  static Future<ScannedCar> upload(XFile image, Uint8List bytes) {
    return _guard(() async {
      final res = await http.post(
        Uri.parse(_baseUrl),
        headers: {..._authHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Encode(bytes),
          'contentType': _contentType(image),
        }),
      );
      if (res.statusCode != 201) throw Exception(_errorOf(res));
      final car = ScannedCar.fromJson(jsonDecode(res.body));
      _imageCache[car.id] = bytes;
      return car;
    });
  }

  static Future<List<ScannedCar>> list() {
    return _guard(() async {
      final res = await http.get(Uri.parse(_baseUrl), headers: _authHeaders);
      if (res.statusCode != 200) throw Exception(_errorOf(res));
      return (jsonDecode(res.body) as List)
          .map((json) => ScannedCar.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<Uint8List> image(String id) {
    final cached = _imageCache[id];
    if (cached != null) return Future.value(cached);
    return _guard(() async {
      final res = await http.get(
        Uri.parse('$_baseUrl/$id/image'),
        headers: _authHeaders,
      );
      if (res.statusCode != 200) throw Exception(_errorOf(res));
      return _imageCache[id] = res.bodyBytes;
    });
  }

  static Future<void> delete(String id) {
    return _guard(() async {
      final res = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: _authHeaders,
      );
      if (res.statusCode != 204) throw Exception(_errorOf(res));
      _imageCache.remove(id);
    });
  }

  static void clearCache() => _imageCache.clear();

  static String _contentType(XFile image) {
    final mime = image.mimeType;
    if (mime != null && mime.startsWith('image/')) return mime;
    final name = image.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
