import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:remoview_mobile/models/film.dart';
import 'package:remoview_mobile/models/film_detail.dart';
import 'package:remoview_mobile/services/token_store.dart';

class FilmService {
  static const String baseUrl = 'https://localhost:7141';
  static const String filmsEndpoint = '/api/films';

  Future<List<Film>> getFilms() async {
    final uri = Uri.parse('$baseUrl$filmsEndpoint');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList =
          json.decode(response.body) as List<dynamic>;
      return jsonList
          .map((e) => Film.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Filmler alınamadı. Status code: ${response.statusCode}');
    }
  }

  Future<FilmDetail> getFilmDetail(int id) async {
    final uri = Uri.parse('$baseUrl$filmsEndpoint/$id');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap =
          json.decode(response.body) as Map<String, dynamic>;
      return FilmDetail.fromJson(jsonMap);
    } else {
      throw Exception(
        'Film detayı alınamadı. Status code: ${response.statusCode}',
      );
    }
  }

  // ✅ Film ekleme (Authorize)
  // Backend FilmCreateDto: { title, posterUrl, genreIds }
  Future<void> createFilm({
    required String title,
    String? posterUrl,
    required List<int> genreIds,
  }) async {
    final token = await TokenStore().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('NO_TOKEN');
    }

    final uri = Uri.parse('$baseUrl$filmsEndpoint');

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'posterUrl': posterUrl,
        'genreIds': genreIds,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Film eklenemedi: ${res.statusCode} ${res.body}');
    }
  }

  // ✅ Sen daha önce buraya ekledin diye varsayıyorum; yoksa dursun
  Future<void> addRating({required int filmId, required int value}) async {
    final token = await TokenStore().getToken();
    if (token == null || token.isEmpty) throw Exception('NO_TOKEN');

    final uri = Uri.parse('$baseUrl/api/Films/$filmId/ratings');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'value': value}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Rating failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> addReview({required int filmId, required String comment}) async {
    final token = await TokenStore().getToken();
    if (token == null || token.isEmpty) throw Exception('NO_TOKEN');

    final uri = Uri.parse('$baseUrl/api/Films/$filmId/reviews');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'comment': comment}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Review failed: ${res.statusCode} ${res.body}');
    }
  }
}
