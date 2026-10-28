import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// Appels au backend : jeton de connexion, erreurs et serveur injoignable
/// sont gérés ici une seule fois.
class Api {
  // sur émulateur Android : flutter run --dart-define=API_HOST=http://10.0.2.2:3000
  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'http://localhost:3000',
  );

  static Future<http.Response> send(
    String method,
    String path, {
    Object? body,
    int expect = 200,
  }) async {
    final request = http.Request(method, Uri.parse('$host/api$path'));
    final token = AuthService.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response res;
    try {
      res = await http.Response.fromStream(await request.send());
    } on http.ClientException {
      throw Exception('Serveur injoignable. Vérifiez votre connexion.');
    }
    if (res.statusCode != expect) throw Exception(_errorOf(res));
    return res;
  }

  /// Comme [send], mais renvoie la réponse JSON déjà décodée.
  static Future<dynamic> json(
    String method,
    String path, {
    Object? body,
    int expect = 200,
  }) async {
    final res = await send(method, path, body: body, expect: expect);
    return jsonDecode(res.body);
  }

  /// Corps JSON d'une photo : le serveur vérifie que le type annoncé
  /// correspond bien au contenu.
  static Map<String, String> imageBody(Uint8List bytes) => {
        'image': base64Encode(bytes),
        'contentType': imageType(bytes),
      };

  static String imageType(Uint8List bytes) {
    bool startsWith(List<int> prefix) =>
        bytes.length >= prefix.length &&
        Iterable<int>.generate(prefix.length)
            .every((i) => bytes[i] == prefix[i]);

    if (startsWith(const [0x89, 0x50, 0x4e, 0x47])) return 'image/png';
    if (startsWith(ascii.encode('RIFF')) &&
        bytes.length >= 12 &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  static String _errorOf(http.Response res) {
    try {
      return jsonDecode(res.body)['error'] as String;
    } catch (_) {
      return 'Erreur du serveur (${res.statusCode})';
    }
  }
}

/// Message d'une erreur à montrer à l'utilisateur.
String errorMessage(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
