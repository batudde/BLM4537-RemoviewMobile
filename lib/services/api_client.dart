import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/favorite_film.dart';
import 'token_store.dart';

class ApiClient {
  // Not: Mobilde "https://localhost:7141" çoğu zaman çalışmaz.
  // Ama sen şimdilik böyle kullanıyorsun diye dokunmadım.
  // Eğer favoriler gelmezse baseUrl'ü sonra düzelteceğiz (10.0.2.2 vs).
  static const String baseUrl = 'https://localhost:7141';

  final TokenStore _tokenStore = TokenStore();

  Future<http.Response> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    return http.get(uri, headers: await _headers());
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    return http.post(
      uri,
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    return http.put(
      uri,
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    return http.delete(uri, headers: await _headers());
  }

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStore.getToken();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<List<FavoriteFilm>> getFavorites() async {
    final res = await get('/api/Favorites');
    if (res.statusCode != 200) {
      throw Exception('getFavorites failed: ${res.statusCode} ${res.body}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => FavoriteFilm.fromJson(e)).toList();
  }

  Future<bool> addFavorite(int filmId) async {
    final res = await post('/api/Favorites/$filmId');
    return res.statusCode == 200;
  }

  Future<bool> removeFavorite(int filmId) async {
    final uri = Uri.parse('$baseUrl/api/Favorites/$filmId');
    final res = await http.delete(uri, headers: await _headers());
    return res.statusCode == 200;
  }
}
