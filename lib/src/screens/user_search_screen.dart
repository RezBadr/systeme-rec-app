import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import 'user_public_profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  static const routeName = '/search-users';

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<User>>? _searchFuture;

  void _doSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchFuture = null;
      });
      return;
    }

    FocusScope.of(context).unfocus(); // remove keyboard and avoid layout jitter

    setState(() {
      _searchFuture = UserService.instance.searchUsers(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche d\'utilisateurs')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(hintText: 'Nom ou email...'),
                    onSubmitted: (_) => _doSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _doSearch, child: const Text('Rechercher')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchFuture == null
                  ? const Center(child: Text('Saisissez une recherche pour démarrer'))
                  : FutureBuilder<List<User>>(
                      future: _searchFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Erreur : ${snapshot.error}'));
                        }

                        final results = snapshot.data ?? [];
                        if (results.isEmpty) {
                          return const Center(child: Text('Aucun utilisateur trouvé.'));
                        }

                        return ListView.separated(
                          primary: false,
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: results.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final user = results[index];
                            return ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 72),
                              child: ListTile(
                                leading: ClipOval(
                                  child: Image.network(
                                    user.avatarUrl ?? 'https://i.pravatar.cc/150?u=${user.id}',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.person, size: 20),
                                    ),
                                  ),
                                ),
                                title: Text(user.username),
                                subtitle: Text(user.email),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.person_add),
                                      tooltip: 'Demande d\'ami',
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        try {
                                          await UserService.instance.sendFriendRequest(user.id);
                                          if (!mounted) return;
                                          messenger.showSnackBar(const SnackBar(content: Text('Demande d\'ami envoyée')));
                                        } catch (e) {
                                          if (!mounted) return;
                                          messenger.showSnackBar(SnackBar(content: Text('Erreur demande d\'ami: $e')));
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward_ios),
                                      tooltip: 'Voir le profil',
                                      onPressed: () {
                                        Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => UserPublicProfileScreen(userId: user.id),
                                        ));
                                      },
                                    ),
                                  ],
                                ),
                              ),
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
