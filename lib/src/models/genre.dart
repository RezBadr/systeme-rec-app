class Genre {
  Genre({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory Genre.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Genre(
      id: parseInt(json['id'] ?? json['genreId'] ?? json['genre_id']),
      name: (json['name'] as String?) ?? (json['title'] as String?) ?? 'Genre inconnu',
    );
  }
}
