import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'auth_service.dart';
import 'recognition.dart';
import 'scanned_car.dart';

class CarService {
  static const String _apiUrl = '${AuthService.host}/api';
  static const String _baseUrl = '$_apiUrl/cars';

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

  static http.Response _expect(http.Response res, int status) {
    if (res.statusCode != status) throw Exception(_errorOf(res));
    return res;
  }

  static Future<http.Response> _postImage(
    String url,
    XFile image,
    Uint8List bytes, {
    Map<String, String> headers = const {},
  }) {
    return http.post(
      Uri.parse(url),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'image': base64Encode(bytes),
        'contentType': _contentType(image),
      }),
    );
  }

  static Future<ScannedCar> upload(XFile image, Uint8List bytes) {
    return _guard(() async {
      final res = _expect(
        await _postImage(_baseUrl, image, bytes, headers: _authHeaders),
        201,
      );
      final car = ScannedCar.fromJson(jsonDecode(res.body));
      _imageCache[car.id] = bytes;
      return car;
    });
  }

  static Future<Recognition> recognize(XFile image, Uint8List bytes) {
    return _guard(() async {
      final res = _expect(
        await _postImage('$_apiUrl/predict', image, bytes),
        200,
      );
      return Recognition.fromJson(jsonDecode(res.body));
    });
  }

  static Future<List<ScannedCar>> list() {
    return _guard(() async {
      final res = _expect(
        await http.get(Uri.parse(_baseUrl), headers: _authHeaders),
        200,
      );
      return (jsonDecode(res.body) as List)
          .map((json) => ScannedCar.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<Uint8List> image(String id) {
    final cached = _imageCache[id];
    if (cached != null) return Future.value(cached);
    return _guard(() async {
      final res = _expect(
        await http.get(Uri.parse('$_baseUrl/$id/image'), headers: _authHeaders),
        200,
      );
      return _imageCache[id] = res.bodyBytes;
    });
  }

  static Future<void> delete(String id) {
    return _guard(() async {
      _expect(
        await http.delete(Uri.parse('$_baseUrl/$id'), headers: _authHeaders),
        204,
      );
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
