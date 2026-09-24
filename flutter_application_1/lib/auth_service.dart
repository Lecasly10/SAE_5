import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // sur émulateur Android : 10.0.2.2 au lieu de localhost
  //static const String baseUrl = 'http://10.0.2.2:3000/api/auth'; // android
  static const String baseUrl = 'http://localhost:3000/api/auth'; // localhost pc

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Erreur');
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
    return data;
  }
}