import '../models/chat_message.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  String? get _token => AuthService.instance.token;
  int? get _userId => AuthService.instance.userId;

  List<dynamic> _extractList(dynamic payload, {List<String> keys = const ['data']}) {
    if (payload is List<dynamic>) {
      return payload;
    }
    if (payload is Map<String, dynamic>) {
      for (final key in keys) {
        final value = payload[key];
        if (value is List<dynamic>) {
          return value;
        }
      }
      final nestedData = payload['data'];
      if (nestedData is List<dynamic>) {
        return nestedData;
      }
      if (nestedData is Map<String, dynamic>) {
        for (final key in keys) {
          final value = nestedData[key];
          if (value is List<dynamic>) {
            return value;
          }
        }
      }
    }
    return const [];
  }

  Future<List<ChatMessage>> fetchMessages(int peerId) async {
    if (_userId == null) return [];
    final data = await ApiService.get('/chat/$_userId/messages/$peerId', token: _token);
    final list = _extractList(data, keys: const ['messages', 'data']);
    return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendMessage(int receiverId, String message) async {
    if (_userId == null) throw Exception('Utilisateur non connecté');
    await ApiService.post('/chat/$_userId/messages', token: _token, body: {
      'receiverId': receiverId,
      'message': message,
    });
  }
}
