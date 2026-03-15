class User {
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.avatarUrl,
    this.coverUrl,
    this.commentCount,
  });

  final int id;
  final String username;
  final String email;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? coverUrl;
  final int? commentCount;

  String get badge {
    final count = commentCount ?? 0;
    if (count >= 10) return 'Maître du feedback (10+)';
    if (count >= 4) return 'Commentateur engagé (4+)';
    return 'Nouveau commentateur';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return User(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      avatarUrl: json['avatarUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      commentCount: parseInt(json['commentCount'] ?? json['commentsCount'] ?? json['comment_count']),
    );
  }
}
