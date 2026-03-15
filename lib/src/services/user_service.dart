import '../models/user.dart';
import '../models/friend_request.dart';
import 'api_service.dart';
import 'auth_service.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

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

  Future<List<User>> searchUsers(String query) async {
    final data = await ApiService.get('/users/search?q=${Uri.encodeComponent(query)}', token: _token);
    final list = _extractList(data, keys: const ['users', 'data']);
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<User?> fetchUserPublic(int userId) async {
    final data = await ApiService.get('/users/$userId/public', token: _token);
    if (data is Map<String, dynamic>) {
      return User.fromJson(data);
    }
    return null;
  }

  Future<void> sendFriendRequest(int receiverId) async {
    if (_userId == null) throw Exception('Utilisateur non connecté');
    await ApiService.post('/users/$_userId/friend-requests', token: _token, body: {'receiverId': receiverId});
  }

  Future<List<FriendRequest>> fetchFriendRequests() async {
    if (_userId == null) return [];
    final data = await ApiService.get('/users/$_userId/friend-requests', token: _token);
    final list = _extractList(data, keys: const ['data', 'requests']);
    return list.map((e) => FriendRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> respondFriendRequest(int requestId, String status) async {
    if (_userId == null) throw Exception('Utilisateur non connecté');
    await ApiService.patch('/users/$_userId/friend-requests/$requestId', token: _token, body: {'status': status});
  }

  Future<int> fetchPendingFriendRequestCount() async {
    final requests = await fetchFriendRequests();
    return requests.where((r) => r.status.toLowerCase() == 'pending').length;
  }

  Future<void> updateProfileImages({String? avatarUrl, String? coverUrl}) async {
    if (_userId == null) throw Exception('Utilisateur non connecté');
    final body = <String, dynamic>{};
    if (avatarUrl != null) {
      body['avatarUrl'] = avatarUrl;
    }
    if (coverUrl != null) {
      body['coverUrl'] = coverUrl;
    }
    await ApiService.patch('/users/$_userId/profile-images', token: _token, body: body);
  }
}
