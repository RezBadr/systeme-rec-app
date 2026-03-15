class Comment {
  Comment({
    required this.id,
    this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final int? userId;
  final String username;
  final String content;
  final DateTime createdAt;

  factory Comment.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }
    String parseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    DateTime parseDate(dynamic value) {
      if (value is String) {
        final dt = DateTime.tryParse(value);
        if (dt != null) return dt;
      }
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return Comment(
      id: parseString(json['id']),
      userId: parseInt(json['userId'] ?? json['user_id']),
      username: parseString(json['username']).isNotEmpty
          ? parseString(json['username'])
          : 'Anonyme',
      content: parseString(json['content']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }
}
