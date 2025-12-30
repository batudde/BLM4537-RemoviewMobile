class FavoriteFilm {
  final int id;
  final String title;
  final String? posterUrl;

  FavoriteFilm({required this.id, required this.title, this.posterUrl});

  factory FavoriteFilm.fromJson(Map<String, dynamic> json) {
    return FavoriteFilm(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      posterUrl: json['posterUrl'] as String?,
    );
  }
}
