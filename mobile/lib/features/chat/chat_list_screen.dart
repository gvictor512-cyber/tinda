import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommatematch/services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  final ChatService _chatService = ChatService();
  StreamSubscription? _chatsSub;

  @override
  void initState() {
    super.initState();
    _listenToConversations();
  }

  @override
  void dispose() {
    _chatsSub?.cancel();
    super.dispose();
  }

  void _listenToConversations() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    _chatsSub = _chatService.getUserChats().listen((chats) async {
      final conversations = <Map<String, dynamic>>[];
      for (final chat in chats) {
        final data = chat.data() as Map<String, dynamic>? ?? {};
        final participants = (data['participants'] as List<dynamic>?) ?? [];
        final otherUserId = participants
          .cast<String?>()
          .firstWhere((id) => id != currentUser.uid, orElse: () => null);
        if (otherUserId == null) continue;
        final otherUser = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .get();
        final otherData = otherUser.data() ?? {};
        final profile = otherData['profile'] as Map<String, dynamic>? ?? {};
        final timestamp = data['lastMessageTimestamp'] as Timestamp?;
        conversations.add({
          'matchId': chat.id,
          'otherUserId': otherUserId,
          'otherUserName': profile['name'] ?? otherData['displayName'] ?? 'Usuario',
          'otherUserPhoto': (profile['photos'] as List<dynamic>?)?.firstOrNull ??
              otherData['photoURL'] as String? ??
              '',
          'lastMessage': data['lastMessage'] as String? ?? '',
          'lastMessageTime': timestamp?.toDate(),
          'unreadCount': 0,
          'compatibilityScore': (otherData['compatibility'] as num?)?.toInt() ?? 0,
        });
      }
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    });
  }

  void _openChat(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matchId: conversation['matchId'],
          otherUserId: conversation['otherUserId'],
          otherUserName: conversation['otherUserName'],
          otherUserPhoto: conversation['otherUserPhoto'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Sin conversaciones',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Haz match para empezar a chatear',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final lastMessage = conversation['lastMessage'] ?? '';
    final lastMessageTime = conversation['lastMessageTime'] as DateTime?;
    final unreadCount = conversation['unreadCount'] ?? 0;
    final compatibilityScore = conversation['compatibilityScore'] ?? 0;

    return InkWell(
      onTap: () => _openChat(conversation),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: conversation['otherUserPhoto'] != null
                      ? NetworkImage(conversation['otherUserPhoto'])
                      : null,
                  child: conversation['otherUserPhoto'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation['otherUserName'] ?? 'Usuario',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (lastMessageTime != null)
                        Text(
                          _formatTime(lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCompatibilityColor(compatibilityScore),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$compatibilityScore%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompatibilityColor(int score) {
    if (score >= 85) return const Color(0xFF27AE60);
    if (score >= 70) return const Color(0xFF4A90E2);
    if (score >= 50) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
