import 'review.dart';

class FilmDetail {
  final int id;
  final String title;
  final String? posterUrl;
  final double averageRating;
  final List<String> genres;
  final List<Review> reviews;

  FilmDetail({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.averageRating,
    required this.genres,
    required this.reviews,
  });

  factory FilmDetail.fromJson(Map<String, dynamic> json) {
    return FilmDetail(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String?,
      averageRating: (json['averageRating'] as num).toDouble(),
      genres: (json['genres'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      reviews: (json['reviews'] as List<dynamic>)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
