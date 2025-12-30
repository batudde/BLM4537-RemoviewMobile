class Review {
  final int id;
  final String comment;
  final DateTime createdAt;
  final int userId;

  Review({
    required this.id,
    required this.comment,
    required this.createdAt,
    required this.userId,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] as num).toInt(),
      comment: (json['comment'] as String?) ?? '',
      userId: (json['userId'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
