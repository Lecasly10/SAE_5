import 'api.dart';

class AuthService {
  static String? token;
  static String? name;
  static String? email;

  /// Accord de l'utilisateur pour que ses photos entraînent l'IA.
  static bool trainingConsent = false;

  static bool get isLoggedIn => token != null;

  static void logout() {
    token = null;
    name = null;
    email = null;
    trainingConsent = false;
  }

  static Future<void> login(String email, String password) async {
    final data = await Api.json(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    token = data['token'] as String;
    _keepAccount(data as Map<String, dynamic>);
  }

  static Future<void> register(
    String name,
    String email,
    String password,
  ) async {
    await Api.send(
      'POST',
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
      expect: 201,
    );
    await login(email, password);
  }

  /// Change le nom, l'e-mail ou l'accord pour entraîner l'IA.
  static Future<void> updateAccount({
    String? name,
    String? email,
    bool? trainingConsent,
  }) async {
    final data = await Api.json('PATCH', '/account', body: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (trainingConsent != null) 'trainingConsent': trainingConsent,
    });
    _keepAccount(data as Map<String, dynamic>);
  }

  /// Supprime le compte, ses voitures et ses photos sur le serveur.
  static Future<void> deleteAccount() async {
    await Api.send('DELETE', '/account', expect: 204);
    logout();
  }

  static void _keepAccount(Map<String, dynamic> data) {
    name = data['name'] as String;
    email = data['email'] as String;
    trainingConsent = data['trainingConsent'] == true;
  }
}
