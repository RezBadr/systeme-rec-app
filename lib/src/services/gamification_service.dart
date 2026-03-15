import 'package:shared_preferences/shared_preferences.dart';

class GamificationService {
  GamificationService._();

  static final GamificationService instance = GamificationService._();

  static const _commentCountKey = 'comment_count';

  Future<int> getCommentCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_commentCountKey) ?? 0;
  }

  Future<void> incrementCommentCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_commentCountKey) ?? 0;
    await prefs.setInt(_commentCountKey, current + 1);
  }

  Future<String> getBadgeLabel() async {
    final count = await getCommentCount();
    if (count >= 10) return 'Maître du commentaire (10+)';
    if (count >= 4) return 'Commentateur engagé (4+)';
    return 'Débutant (0-3 commentaires)';
  }

  String badgeFromCount(int count) {
    if (count >= 10) return 'Maître du commentaire (10+)';
    if (count >= 4) return 'Commentateur engagé (4+)';
    return 'Débutant (0-3 commentaires)';
  }
}
