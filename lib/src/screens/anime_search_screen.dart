import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../models/genre.dart';
import '../services/anime_service.dart';
import '../widgets/anime_card.dart';
import 'anime_detail_screen.dart';

class AnimeSearchScreen extends StatefulWidget {
  const AnimeSearchScreen({super.key});

  static const routeName = '/search-anime';

  @override
  State<AnimeSearchScreen> createState() => _AnimeSearchScreenState();
}

class _AnimeSearchScreenState extends State<AnimeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedGenreId;
  Future<List<Anime>>? _searchFuture;
  late Future<List<Genre>> _genresFuture;

  @override
  void initState() {
    super.initState();
    _genresFuture = AnimeService.instance.fetchGenres();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();

    if ((query.isEmpty) && _selectedGenreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrez un titre ou un genre.')));
      return;
    }

    setState(() {
      if (_selectedGenreId != null && query.isEmpty) {
        _searchFuture = AnimeService.instance.fetchAnimesByGenre(_selectedGenreId!);
      } else if ((_selectedGenreId != null) && query.isNotEmpty) {
        _searchFuture = AnimeService.instance.fetchAnimesByGenre(_selectedGenreId!).then((list) {
          final lowerQuery = query.toLowerCase();
          return list.where((anime) => anime.title.toLowerCase().contains(lowerQuery)).toList();
        });
      } else {
        _searchFuture = AnimeService.instance.searchAnimes(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche d\'anime')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Genre>>(
              future: _genresFuture,
              builder: (context, snapshot) {
                final genres = snapshot.data ?? [];
                if (snapshot.hasError) {
                  return const SizedBox();
                }
                return DropdownButtonFormField<int?>(
                  initialValue: _selectedGenreId,
                  decoration: const InputDecoration(labelText: 'Filtrer par genre', border: OutlineInputBorder()),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Tous les genres')),
                    ...genres.map((g) => DropdownMenuItem<int?>(value: g.id, child: Text(g.name))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGenreId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _search, child: const Text('Rechercher')),
            const SizedBox(height: 16),
            Expanded(
              child: _searchFuture == null
                  ? const Center(child: Text('Recherchez un anime par nom ou par genre.'))
                  : FutureBuilder<List<Anime>>(
                      future: _searchFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Erreur : ${snapshot.error}'));
                        }
                        final list = snapshot.data ?? [];
                        if (list.isEmpty) {
                          return const Center(child: Text('Aucun anime trouvé.'));
                        }
                        return ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final anime = list[index];
                            return AnimeCard(
                              anime: anime,
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => AnimeDetailScreen(animeId: anime.id.toString()),
                                ));
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
