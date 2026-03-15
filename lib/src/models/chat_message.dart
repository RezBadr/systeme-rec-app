class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
  });

  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return ChatMessage(
      id: parseInt(json['id']),
      senderId: parseInt(json['senderId'] ?? json['sender_id']),
      receiverId: parseInt(json['receiverId'] ?? json['receiver_id']),
      message: (json['message'] as String?) ?? '',
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }
}
