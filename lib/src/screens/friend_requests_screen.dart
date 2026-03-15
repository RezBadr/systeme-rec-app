import 'package:flutter/material.dart';

import '../models/friend_request.dart';
import '../services/user_service.dart';
import 'user_public_profile_screen.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  static const routeName = '/friend-requests';

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  late Future<List<FriendRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _requestsFuture = UserService.instance.fetchFriendRequests();
  }

  Future<void> _respond(FriendRequest request, String status) async {
    try {
      await UserService.instance.respondFriendRequest(request.id, status);
      _load();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Demande ${status == 'accepted' ? 'acceptée' : 'refusée'}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes d\'amis')),
      body: FutureBuilder<List<FriendRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));}

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('Aucune demande reçue.'));
          }

          return ListView.separated(
            itemCount: requests.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final req = requests[index];
              return ListTile(
                title: Text('Demande de ${req.senderId}'),
                subtitle: Text('Statut : ${req.status}'),
                onTap: () {
                  if (req.senderId > 0) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => UserPublicProfileScreen(userId: req.senderId),
                    ));
                  }
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(onPressed: () => _respond(req, 'accepted'), child: const Text('Accepter')),
                    TextButton(onPressed: () => _respond(req, 'rejected'), child: const Text('Refuser')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
