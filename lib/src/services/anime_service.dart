import '../models/anime.dart';
import '../models/comment.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'auth_service.dart';

class AnimeService {
  AnimeService._();

  static final AnimeService instance = AnimeService._();

  String? get _token => AuthService.instance.token;

  Future<User?> fetchUserProfile() async {
    final userId = AuthService.instance.userId;
    if (userId == null) return null;

    final data = await ApiService.get('/users/$userId', token: _token);
    if (data is Map<String, dynamic>) {
      return User.fromJson(data);
    }

    return null;
  }

  Future<Map<String, dynamic>?> fetchUserPublicData() async {
    final userId = AuthService.instance.userId;
    if (userId == null) return null;

    final data = await ApiService.get('/users/$userId/public', token: _token);
    if (data is Map<String, dynamic>) {
      return data;
    }

    return null;
  }

  Future<int> fetchSeenCount() async {
    try {
      final publicData = await fetchUserPublicData();
      if (publicData == null) return 0;
      return (publicData['watchedCount'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> fetchWatchLaterCount() async {
    try {
      final publicData = await fetchUserPublicData();
      if (publicData == null) return 0;
      final watchLater = (publicData['watchLater'] as List<dynamic>?) ?? [];
      return watchLater.length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Anime>> fetchSeenAnimes() async {
    // If the backend does not provide full seen anime list, fallback to empty list.
    // Keep this method for future extension.
    return [];
  }

  Future<List<Anime>> fetchWatchLaterAnimes() async {
    final userId = AuthService.instance.userId;
    if (userId == null) return [];

    try {
      final publicData = await fetchUserPublicData();
      if (publicData == null) return [];

      final watchLaterIds = (publicData['watchLater'] as List<dynamic>?) ?? [];
      final futures = watchLaterIds
          .map((id) => fetchAnimeDetail(id.toString()))
          .toList();

      final items = await Future.wait(futures);
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<List<Anime>> fetchRecommendedByContent(int userId) async {
    final data = await ApiService.get('/recommendations/$userId?limit=20&type=content', token: _token);
    final items = (data as Map<String, dynamic>)['recommendations'] as List<dynamic>? ?? [];
    return items.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Anime>> fetchRecommendedByCollaboration(int userId) async {
    final data = await ApiService.get('/recommendations/$userId?limit=20&type=collaboration', token: _token);
    final items = (data as Map<String, dynamic>)['recommendations'] as List<dynamic>? ?? [];
    return items.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Anime>> fetchAllAnime() async {
    final data = await ApiService.get('/animes', token: _token);
    final list = (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return list.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Anime> fetchAnimeDetail(String animeId) async {
    final data = await ApiService.get('/animes/$animeId', token: _token);
    return Anime.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Comment>> fetchComments(String animeId) async {
    try {
      final data = await ApiService.get('/comments/anime/$animeId', token: _token);
      final list = (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
      return list.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      // backend may return 500 when no comments or route passthrough issue;
      // on erreur, on retourne simplement une liste vide au lieu d'écraser l'UI.
      // ignore: avoid_print
      print('fetchComments error for anime $animeId: $e');
      return [];
    }
  }

  Future<void> postComment(String animeId, String content) async {
    if (AuthService.instance.userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    await ApiService.post(
      '/comments',
      token: _token,
      body: {
        'userId': AuthService.instance.userId,
        'animeId': int.tryParse(animeId) ?? 0,
        'content': content,
      },
    );
  }

  Future<void> rateAnime(String animeId, double rating) async {
    await ApiService.post(
      '/animes/$animeId/rating',
      token: _token,
      body: {'userId': AuthService.instance.userId, 'score': rating},
    );
  }

  Future<void> addToFavorites(String animeId) async {
    final userId = AuthService.instance.userId;
    if (userId == null) throw Exception('Utilisateur non connecté');
    await ApiService.post(
      '/users/$userId/favorites',
      token: _token,
      body: {'animeId': int.tryParse(animeId) ?? 0},
    );
  }

  Future<void> addToWatchLater(String animeId) async {
    final userId = AuthService.instance.userId;
    if (userId == null) throw Exception('Utilisateur non connecté');
    await ApiService.post(
      '/users/$userId/watch-later',
      token: _token,
      body: {'animeId': int.tryParse(animeId) ?? 0},
    );
  }
}
