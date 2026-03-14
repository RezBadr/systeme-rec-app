import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../services/anime_service.dart';
import '../services/auth_service.dart';
import '../widgets/anime_card.dart';
import 'anime_detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
  }

  Future<List<Anime>> _fetchForTab(int tabIndex) {
    final userId = AuthService.instance.userId;
    if (userId == null) {
      return Future.value([]);
    }

    switch (tabIndex) {
      case 0:
        return AnimeService.instance.fetchRecommendedByContent(userId);
      case 1:
        return AnimeService.instance.fetchRecommendedByCollaboration(userId);
      case 2:
      default:
        return AnimeService.instance.fetchAllAnime();
    }
  }

  String _titleForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Recommandés (contenu)';
      case 1:
        return 'Recommandés (collaboration)';
      case 2:
      default:
        return 'Tous les animes';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anime Recommandation'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Contenu'),
            Tab(text: 'Collab'),
            Tab(text: 'Tous'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(3, (index) {
          return FutureBuilder<List<Anime>>(
            future: _fetchForTab(index),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Erreur : ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Text('Aucun anime trouvé pour «${_titleForTab(index)}».\nEssayez de rafraîchir.',
                      textAlign: TextAlign.center),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final anime = items[index];
                    return AnimeCard(
                      anime: anime,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AnimeDetailScreen(animeId: anime.id.toString()),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
