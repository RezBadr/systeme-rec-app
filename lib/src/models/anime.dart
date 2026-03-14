class Anime {
  Anime({
    required this.id,
    required this.title,
    this.synopsis,
    this.imageUrl,
    this.score,
    this.popularity,
    this.genreIds,
  });

  final int id;
  final String title;
  final String? synopsis;
  final String? imageUrl;
  final double? score;
  final int? popularity;
  final List<int>? genreIds;

  factory Anime.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    final dynamic rawGenres = json['genres'] ?? json['genreIds'];

    return Anime(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title'] as String? ?? '',
      synopsis: json['synopsis'] as String? ?? json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      score: parseDouble(json['score']) ?? parseDouble(json['averageRating']),
      popularity: parseInt(json['popularity']),
      genreIds: (rawGenres is List<dynamic>)
          ? rawGenres.map((e) => parseInt(e) ?? 0).where((e) => e > 0).toList()
          : null,
    );
  }
}
