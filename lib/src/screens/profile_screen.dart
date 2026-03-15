import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../models/user.dart';
import '../services/anime_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/gamification_service.dart';
import 'friend_requests_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User?> _profileFuture;
  late Future<int> _seenCountFuture;
  late Future<int> _watchLaterCountFuture;
  late Future<int> _pendingRequestsFuture;
  late Future<int> _commentCountFuture;
  late Future<List<Anime>> _watchLaterListFuture;

  final TextEditingController _avatarUrlController = TextEditingController();
  final TextEditingController _coverUrlController = TextEditingController();
  bool _isUpdatingImages = false;


  @override
  void initState() {
    super.initState();
    _profileFuture = AnimeService.instance.fetchUserProfile();
    _seenCountFuture = AnimeService.instance.fetchSeenCount();
    _watchLaterCountFuture = AnimeService.instance.fetchWatchLaterCount();
    _pendingRequestsFuture = UserService.instance.fetchPendingFriendRequestCount();
    _commentCountFuture = GamificationService.instance.getCommentCount();
    _watchLaterListFuture = AnimeService.instance.fetchWatchLaterAnimes();
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = AnimeService.instance.fetchUserProfile();
      _seenCountFuture = AnimeService.instance.fetchSeenCount();
      _watchLaterCountFuture = AnimeService.instance.fetchWatchLaterCount();
      _pendingRequestsFuture = UserService.instance.fetchPendingFriendRequestCount();
      _commentCountFuture = GamificationService.instance.getCommentCount();
      _watchLaterListFuture = AnimeService.instance.fetchWatchLaterAnimes();
    });
  }

  Future<void> _updateProfileImages() async {
    if (!_avatarUrlController.text.trim().isNotEmpty && !_coverUrlController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez saisir au moins un URL.')));
      return;
    }

    setState(() => _isUpdatingImages = true);
    try {
      await UserService.instance.updateProfileImages(
        avatarUrl: _avatarUrlController.text.trim().isNotEmpty ? _avatarUrlController.text.trim() : null,
        coverUrl: _coverUrlController.text.trim().isNotEmpty ? _coverUrlController.text.trim() : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Images de profil mises à jour.')));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur mise à jour images : $e')));
    } finally {
      if (mounted) setState(() => _isUpdatingImages = false);
    }
  }

  @override
  void dispose() {
    _avatarUrlController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<User?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Text('Impossible de charger les informations du profil.');
                }

                final user = snapshot.data;
                if (user == null) {
                  return const Text('Utilisateur non trouvé.');
                }

                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        ClipOval(
                          child: Image.network(
                            user.avatarUrl ?? 'https://i.pravatar.cc/150?u=${user.id}',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 72,
                              height: 72,
                              color: Colors.grey[200],
                              child: const Icon(Icons.person, size: 36),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(user.email, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 6),
                              Text('Membre depuis ${user.createdAt.toLocal().toString().split(' ')[0]}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            FutureBuilder<int>(
              future: _seenCountFuture,
              builder: (context, snapshot) {
                final count = (snapshot.data ?? 0);
                return ListTile(
                  leading: const Icon(Icons.remove_red_eye),
                  title: const Text('Anime déjà vus'),
                  trailing: Text(count.toString()),
                );
              },
            ),
            FutureBuilder<int>(
              future: _watchLaterCountFuture,
              builder: (context, snapshot) {
                final count = (snapshot.data ?? 0);
                return ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Anime à voir plus tard'),
                  trailing: Text(count.toString()),
                );
              },
            ),
            FutureBuilder<int>(
              future: _pendingRequestsFuture,
              builder: (context, snapshot) {
                final pending = (snapshot.data ?? 0);
                return ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Invitations en attente'),
                  trailing: Text(pending.toString()),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FriendRequestsScreen()));
                  },
                );
              },
            ),
            FutureBuilder<int>(
              future: _commentCountFuture,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return ListTile(
                  leading: const Icon(Icons.handshake),
                  title: const Text('Commentaires postés'),
                  trailing: Text(count.toString()),
                );
              },
            ),
            FutureBuilder<int>(
              future: _commentCountFuture,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                final badge = GamificationService.instance.badgeFromCount(count);
                return ListTile(
                  leading: const Icon(Icons.emoji_events),
                  title: const Text('Badge gamification'),
                  trailing: Text(badge),
                );
              },
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mettre à jour avatar / couverture', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _avatarUrlController,
                      decoration: const InputDecoration(hintText: 'URL de l\'avatar'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _coverUrlController,
                      decoration: const InputDecoration(hintText: 'URL de la couverture'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isUpdatingImages ? null : _updateProfileImages,
                      child: _isUpdatingImages
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Mettre à jour les images'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Liste à voir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<Anime>>(
              future: _watchLaterListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Text('Impossible de charger la liste à voir.');
                }

                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Text('Aucun anime dans la liste de visionnage.');
                }

                return Column(
                  children: list.map((anime) {
                    return ListTile(
                      title: Text(anime.title),
                      subtitle: Text('Score: ${anime.score?.toStringAsFixed(1) ?? '-'}'),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (!mounted) return;
                final navigator = Navigator.of(context);
                await AuthService.instance.logout();
                if (!mounted) return;
                navigator.pushReplacementNamed('/login');
              },
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
