import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/anime.dart';
import '../models/comment.dart';
import '../models/genre.dart';
import '../screens/user_public_profile_screen.dart';
import '../services/anime_service.dart';
import '../services/gamification_service.dart';

class AnimeDetailScreen extends StatefulWidget {
  const AnimeDetailScreen({super.key, required this.animeId});

  final String animeId;

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  late Future<Anime> _animeFuture;
  late Future<List<Comment>> _commentsFuture;
  late Future<List<Genre>> _genresFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _animeFuture = AnimeService.instance.fetchAnimeDetail(widget.animeId);
    _commentsFuture = AnimeService.instance.fetchComments(widget.animeId);
    _genresFuture = AnimeService.instance.fetchGenres();
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    if (!mounted) return;
    setState(() => _isPostingComment = true);
    try {
      await AnimeService.instance.postComment(widget.animeId, content);
      await GamificationService.instance.incrementCommentCount();
      final commentCount = await GamificationService.instance.getCommentCount();
      final badgeMessage = () {
        if (commentCount == 4) return 'Bravo ! Vous avez débloqué un badge Commentateur engagé.';
        if (commentCount == 10) return 'Félicitations ! Badge Maître du commentaire débloqué.';
        return null;
      }();

      _commentController.clear();
      if (!mounted) return;
      setState(() {
        _commentsFuture = AnimeService.instance.fetchComments(widget.animeId);
      });

      if (badgeMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(badgeMessage)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi du commentaire : $e')),
      );
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  Future<void> _rate(double rating) async {
    try {
      await AnimeService.instance.rateAnime(widget.animeId, rating);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci pour votre note !')),
      );
      setState(() {
        _animeFuture = AnimeService.instance.fetchAnimeDetail(widget.animeId);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ajouter la note : $e')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildBody(Anime anime) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (anime.imageUrl != null && anime.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                anime.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  color: Colors.black12,
                  child: const Center(child: Icon(Icons.broken_image, size: 40)),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            anime.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (anime.genreIds != null && anime.genreIds!.isNotEmpty)
            FutureBuilder<List<Genre>>(
              future: _genresFuture,
              builder: (context, genresSnapshot) {
                final genres = genresSnapshot.data ?? [];
                final mapGenre = {for (var g in genres) g.id: g.name};
                final genreText = anime.genreIds!
                    .map((id) => mapGenre[id] ?? 'Genre $id')
                    .join(' • ');
                return Text(genreText, style: Theme.of(context).textTheme.bodyMedium);
              },
            ),
          const SizedBox(height: 12),
          if (anime.synopsis != null && anime.synopsis!.isNotEmpty)
            Text(
              anime.synopsis!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Votre note', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RatingBar.builder(
                    initialRating: anime.score ?? 0,
                    minRating: 1,
                    allowHalfRating: true,
                    itemCount: 5,
                    direction: Axis.horizontal,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: _rate,
                  ),
                  const SizedBox(height: 12),
                  if (anime.score != null)
                    Text('Note moyenne: ${anime.score!.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.favorite_border),
                label: const Text('Ajouter aux favoris'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await AnimeService.instance.addToFavorites(widget.animeId);
                    if (!mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('Ajouté aux favoris')));
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text('Erreur favori : $e')));
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.watch_later_outlined),
                label: const Text('À voir plus tard'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await AnimeService.instance.addToWatchLater(widget.animeId);
                    if (!mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('Ajouté à la liste à voir plus tard')));
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text('Erreur watch later : $e')));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Commentaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return FutureBuilder<List<Comment>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data ?? [];

        // Tu as un backend qui renvoie parfois 500 pour les commentaires.
        // On ignore ce cas et on affiche l'état sans faire planter l'affichage.
        if (snapshot.hasError) {
          debugPrint('comment load error: ${snapshot.error}');
        }
        return Column(
          children: [
            for (final comment in comments)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(comment.username),
                  subtitle: Text(comment.content),
                  trailing: Text(
                    _formatDate(comment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: comment.userId != null
                      ? () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => UserPublicProfileScreen(userId: comment.userId!),
                          ));
                        }
                      : null,
                ),
              ),
            if (comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Aucun commentaire pour le moment. Soyez le premier !'),
              ),
            const Divider(),
            TextField(
              controller: _commentController,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Ajouter un commentaire...',
                suffixIcon: IconButton(
                  icon: _isPostingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isPostingComment ? null : _postComment,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.difference(now).inDays == 0) {
      return 'aujourd\'hui';
    }
    if (date.difference(now).inDays == -1) {
      return 'hier';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails de l\'anime')),
      body: FutureBuilder<Anime>(
        future: _animeFuture,
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
                        setState(() {
                          _loadData();
                        });
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final anime = snapshot.data!;
          return _buildBody(anime);
        },
      ),
    );
  }
}
