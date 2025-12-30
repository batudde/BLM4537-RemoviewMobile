class Film {
  final int id;
  final String title;
  final String? posterUrl;
  final double averageRating;
  final List<String> genres;

  Film({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.averageRating,
    required this.genres,
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    final dynamic ratingJson = json['averageRating'];

    double parsedRating = 0;
    if (ratingJson is int) parsedRating = ratingJson.toDouble();
    if (ratingJson is double) parsedRating = ratingJson;

    return Film(
      id: (json['id'] ?? 0) as int,
      title: (json['title'] ?? '') as String,
      posterUrl: json['posterUrl'] as String?,
      averageRating: parsedRating,
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterUrl': posterUrl,
      'averageRating': averageRating,
      'genres': genres,
    };
  }
}
