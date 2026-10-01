import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // sur émulateur Android : 10.0.2.2 au lieu de localhost
  //static const String host = 'http://10.0.2.2:3000'; // android
  static const String host = 'http://localhost:3000'; // localhost pc
  static const String baseUrl = '$host/api/auth';

  static String? token;
  static String? name;
  static String? email;

  static bool get isLoggedIn => token != null;

  static void logout() {
    token = null;
    name = null;
    email = null;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Erreur');
    AuthService.token = data['token'];
    AuthService.name = data['name'];
    AuthService.email = data['email'];
    return data;
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 201) throw Exception(data['error'] ?? 'Erreur');
    return login(email, password);
  }
}
