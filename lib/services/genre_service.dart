import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:remoview_mobile/models/genre.dart';

class GenreService {
  static const String baseUrl = 'https://localhost:7141';

  Future<List<Genre>> getGenres() async {
    final uri = Uri.parse('$baseUrl/api/genres');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final list = json.decode(res.body) as List<dynamic>;
      return list
          .map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Genres alınamadı: ${res.statusCode} ${res.body}');
  }
}
