class Comment {
  Comment({
    required this.id,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String content;
  final DateTime createdAt;

  factory Comment.fromJson(Map<String, dynamic> json) {
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
      username: parseString(json['username']).isNotEmpty
          ? parseString(json['username'])
          : 'Anonyme',
      content: parseString(json['content']),
      createdAt: parseDate(json['createdAt']),
    );
  }
}
