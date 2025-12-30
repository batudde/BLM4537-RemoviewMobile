import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://localhost:7141';

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/Auth/register');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Register failed: ${res.statusCode} ${res.body}');
    }

    // ✅ Register token dönmüyor olabilir, sorun değil.
    // İstersen message’ı okuyup UI’da gösterebilirsin.
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/Auth/login');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Login failed: ${res.statusCode} ${res.body}');
    }

    // ✅ Login response token dönmeli
    final body = res.body.trim();

    // 1) direkt string dönme ihtimali
    if (!body.startsWith('{')) {
      return body.replaceAll('"', '');
    }

    // 2) json objesi dönme ihtimali
    final map = jsonDecode(body) as Map<String, dynamic>;

    final token =
        (map['token'] ??
                map['accessToken'] ??
                map['jwt'] ??
                map['data'] ??
                map['result'])
            ?.toString();

    if (token == null || token.isEmpty) {
      throw Exception('Token parse edilemedi. Response: $body');
    }

    return token;
  }
}
