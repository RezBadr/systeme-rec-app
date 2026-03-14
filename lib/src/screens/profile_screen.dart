import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../models/user.dart';
import '../services/anime_service.dart';
import '../services/auth_service.dart';

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
  late Future<List<Anime>> _watchLaterListFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AnimeService.instance.fetchUserProfile();
    _seenCountFuture = AnimeService.instance.fetchSeenCount();
    _watchLaterCountFuture = AnimeService.instance.fetchWatchLaterCount();
    _watchLaterListFuture = AnimeService.instance.fetchWatchLaterAnimes();
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = AnimeService.instance.fetchUserProfile();
      _seenCountFuture = AnimeService.instance.fetchSeenCount();
      _watchLaterCountFuture = AnimeService.instance.fetchWatchLaterCount();
      _watchLaterListFuture = AnimeService.instance.fetchWatchLaterAnimes();
    });
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
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${user.id}'),
                          backgroundColor: Colors.grey[200],
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
