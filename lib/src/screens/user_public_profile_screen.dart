import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/chat_message.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';

class UserPublicProfileScreen extends StatefulWidget {
  const UserPublicProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  State<UserPublicProfileScreen> createState() => _UserPublicProfileScreenState();
}

class _UserPublicProfileScreenState extends State<UserPublicProfileScreen> {
  late Future<User?> _userFuture;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _userFuture = UserService.instance.fetchUserPublic(widget.userId);
  }

  Future<void> _sendFriendRequest(int receiverId) async {
    setState(() => _isRequesting = true);
    try {
      await UserService.instance.sendFriendRequest(receiverId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande d\'ami envoyée')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<void> _openChat(int peerId) async {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(peerId: peerId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil utilisateur')),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Utilisateur non trouvé'));}

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (user.coverUrl != null && user.coverUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    user.coverUrl!,
                    height: 140,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(height: 140, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image))),
                  ),
                ),
              const SizedBox(height: 12),
              ClipOval(
                child: Image.network(
                  user.avatarUrl ?? 'https://i.pravatar.cc/150?u=${user.id}',
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 84,
                    height: 84,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(user.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user.email, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Chip(label: Text('Badge: ${user.badge}')),
              const SizedBox(height: 12),
              Text('Commentaires totaux : ${user.commentCount ?? 0}'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: AuthService.instance.userId == widget.userId || _isRequesting
                    ? null
                    : () => _sendFriendRequest(widget.userId),
                icon: const Icon(Icons.person_add),
                label: const Text('Ajouter en ami'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: widget.userId == AuthService.instance.userId
                    ? null
                    : () => _openChat(widget.userId),
                icon: const Icon(Icons.chat),
                label: const Text('Démarrer le chat'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _openChat(widget.userId),
                icon: const Icon(Icons.chat),
                label: const Text('Démarrer le chat'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.peerId});

  final int peerId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Future<List<ChatMessage>> _conversationFuture;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  void _loadConversation() {
    _conversationFuture = ChatService.instance.fetchMessages(widget.peerId);
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    try {
      await ChatService.instance.sendMessage(widget.peerId, text);
      if (!mounted) return;
      _messageController.clear();
      _loadConversation();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chat: $e')));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<ChatMessage>>(
              future: _conversationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('Pas encore de messages.')); }
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final text = msg.message;
                    final senderId = msg.senderId;
                    final currentUserId = AuthService.instance.userId;
                    final isMine = currentUserId != null && currentUserId == senderId;
                    return ListTile(
                      title: Text(text),
                      subtitle: Text('Envoyé par $senderId'),
                      tileColor: isMine ? Colors.blue.shade50 : Colors.grey.shade100,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Votre message...'),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
