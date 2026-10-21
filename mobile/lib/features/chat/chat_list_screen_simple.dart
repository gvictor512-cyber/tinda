import 'package:flutter/material.dart';

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:image_picker/image_picker.dart';

import '../../services/chat_service.dart';

import '../../services/matching_service.dart';

import '../../services/auth_service.dart';

import '../profile/profile_details_screen.dart';

import '../../config/theme.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

  final AuthService _authService = AuthService();

  // Caches user docs so list rebuilds don't re-fetch every profile
  final Map<String, Future<DocumentSnapshot>> _userDocCache = {};

  // Cached stream: avoids resubscribing to Firestore on every rebuild
  late final Stream<List<QueryDocumentSnapshot>> _chatsStream =
      _chatService.getUserChats();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mensajes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _chatsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudieron cargar los mensajes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text('Desliza hacia abajo para reintentar'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 24),
                  const Text(
                    'No tienes conversaciones',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Haz match con alguien para empezar a chatear'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshConversations,
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final chatDoc = snapshot.data![index];

                final chatData = chatDoc.data() as Map<String, dynamic>;

                final participants = chatData['participants'] as List?;

                if (participants == null || participants.isEmpty) {
                  return const SizedBox.shrink();
                }

                final otherUserId = participants.firstWhere(
                  (id) => id != _authService.currentUser?.uid,
                  orElse: () => null,
                );

                // Malformed doc or a chat with only the current user —
                // skip the tile instead of crashing the whole list.
                if (otherUserId == null) {
                  return const SizedBox.shrink();
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: _userDocCache.putIfAbsent(
                      otherUserId as String,
                      () => FirebaseFirestore.instance
                          .collection('profiles')
                          .doc(otherUserId)
                          .get()),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData || userSnapshot.data == null) {
                      return const SizedBox();
                    }

                    if (userSnapshot.hasError) {
                      return const SizedBox.shrink();
                    }

                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;

                    // Perfil borrado o inexistente: se oculta la conversacion
                    // en vez de mostrar un tile vacio ("Usuario no encontrado").
                    if (userData == null) {
                      return const SizedBox.shrink();
                    }

                    // Seeded demo conversations only show for the
                    // demo/dev accounts — real users see organic chats.
                    if (!MatchingService.canSeeDemoContent &&
                        userData['isDemo'] == true) {
                      return const SizedBox.shrink();
                    }

                    final name = userData['name'] as String? ?? 'Usuario';

                    final photoUrl = userData['photoURL'] as String?;

                    final lastMessage =
                        chatData['lastMessage'] as String? ?? '';

                    final lastMessageTimestamp =
                        chatData['lastMessageTimestamp'] as Timestamp?;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        ChatScreen(
                                  userId: otherUserId,
                                  userName: name,
                                  userPhoto: photoUrl,
                                ),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);

                                  const end = Offset.zero;

                                  const curve = Curves.easeInOut;

                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));

                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 300),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          splashColor:
                              AppTheme.primaryBlue.withValues(alpha: 0.1),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppTheme.darkSurface
                                  : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? 0.2
                                          : 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      _openUserProfile(otherUserId, userData),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primaryBlue
                                            .withValues(alpha: 0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: Hero(
                                      tag: 'profile-$otherUserId',
                                      child: CircleAvatar(
                                        backgroundImage: photoUrl != null
                                            ? CachedNetworkImageProvider(
                                                photoUrl,
                                                maxWidth: 200)
                                            : null,
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppTheme.darkSurface
                                                : const Color(0xFFF1F5F9),
                                        child: photoUrl == null
                                            ? Text(
                                                (name.isNotEmpty ? name[0] : '?')
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.primaryBlue,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _openUserProfile(
                                            otherUserId, userData),
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? AppTheme.textLight
                                                    : AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppTheme.textLightSecondary
                                              : AppTheme.textDarkSecondary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (lastMessageTimestamp != null)
                                      Text(
                                        _formatTimestamp(lastMessageTimestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppTheme.textLightSecondary
                                              : AppTheme.textDarkSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openUserProfile(String userId,
      [Map<String, dynamic>? prefetched]) async {
    try {
      final data = prefetched ??
          (await FirebaseFirestore.instance
                  .collection('profiles')
                  .doc(userId)
                  .get())
              .data();
      if (!mounted) return;
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar el perfil')),
        );
        return;
      }
      final profile = <String, dynamic>{
        ...data,
        if (data['profile'] is Map)
          ...(data['profile'] as Map).cast<String, dynamic>(),
        'name': data['name'],
        'uid': userId,
      };
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProfileDetailsScreen(profile: profile)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el perfil: $e')),
        );
      }
    }
  }

  // The stream is live, so refresh just gives the gesture a moment to
  // visually settle — new events arrive automatically.
  Future<void> _refreshConversations() =>
      Future.delayed(const Duration(milliseconds: 400));

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();

    final messageTime = timestamp.toDate();

    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${messageTime.day}/${messageTime.month}';
    }
  }
}

class ChatScreen extends StatefulWidget {
  final String userId;

  final String userName;

  final String? userPhoto;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();

  final AuthService _authService = AuthService();

  final TextEditingController _messageController = TextEditingController();

  bool _sendingImage = false;

  @override
  void initState() {
    super.initState();

    _markMessagesAsRead();

    _messagesStream = _chatService.getMessages(widget.userId);
    _onlineStatusStream = _chatService.getOnlineStatus(widget.userId);
  }

  // Cached streams: prevents resubscribing to Firestore on every rebuild
  late final Stream<QuerySnapshot> _messagesStream;
  late final Stream<DocumentSnapshot> _onlineStatusStream;

  Future<void> _openUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get();
      if (!mounted) return;
      final data = doc.data();
      if (data == null) return;
      final profile = <String, dynamic>{
        ...data,
        if (data['profile'] is Map)
          ...(data['profile'] as Map).cast<String, dynamic>(),
        'name': data['name'],
        'uid': widget.userId,
      };
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProfileDetailsScreen(profile: profile)),
      );
    } catch (e) {
      debugPrint('Error al abrir perfil: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(widget.userId);
  }

  void _showReportDialog() {
    final reasons = [
      'Contenido inapropiado',
      'Perfil falso',
      'Spam',
      'Comportamiento abusivo',
      'Otro',
    ];

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Reportar usuario'),
        children: [
          ...reasons.map((reason) => SimpleDialogOption(
                child: Text(reason),
                onPressed: () {
                  Navigator.of(context).pop();
                  _reportUser(reason);
                },
              )),
          SimpleDialogOption(
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _reportUser(String reason) async {
    try {
      await _chatService.reportUser(
        userId: widget.userId,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte enviado. Gracias.')),
        );
      }
    } catch (e) {
      debugPrint('Error al reportar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No se pudo enviar el reporte. Inténtalo de nuevo.')),
        );
      }
    }
  }

  Future<void> _blockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear usuario'),
        content: Text(
          '¿Bloquear a ${widget.userName}? No podréis enviaros mensajes ni ver vuestros perfiles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _chatService.blockUser(widget.userId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error al bloquear: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No se pudo bloquear al usuario. Inténtalo de nuevo.')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) return;

    // Optimistic UI: clear input instantly so sending feels immediate
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        receiverId: widget.userId,
        message: message,
      );
    } catch (e) {
      // Restore the message so the user doesn't lose it
      _messageController.text = message;
      debugPrint('Error al enviar mensaje: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No se pudo enviar el mensaje. Inténtalo de nuevo.')),
        );
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _sendingImage = true);
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) throw StateError('No autenticado');
      final chatId = ([uid, widget.userId]..sort()).join('_');
      final ref = FirebaseStorage.instance.ref().child(
          'chat_images/${chatId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await _chatService.sendMessage(
        receiverId: widget.userId,
        message: '📷 Foto',
        imageUrl: url,
      );
    } catch (e) {
      debugPrint('Error al enviar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No se pudo enviar la imagen. Inténtalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: GestureDetector(
          onTap: _openUserProfile,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: widget.userPhoto != null
                      ? CachedNetworkImageProvider(widget.userPhoto!,
                          maxWidth: 200)
                      : null,
                  backgroundColor:
                      isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface,
                  child: widget.userPhoto == null
                      ? Text(
                          (widget.userName.isNotEmpty
                                  ? widget.userName[0]
                                  : '?')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color:
                            isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                      ),
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream: _onlineStatusStream,
                      builder: (context, snapshot) {
                        final data =
                            snapshot.data?.data() as Map<String, dynamic>?;

                        // Staleness: an app killed abruptly may leave
                        // isOnline=true — require lastActive within 5 min.
                        final lastActive =
                            data?['lastActive'] as Timestamp?;
                        final isOnline = (data?['isOnline'] ?? false) &&
                            lastActive != null &&
                            lastActive.toDate().isAfter(DateTime.now()
                                .subtract(const Duration(minutes: 5)));

                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color:
                                    isOnline ? AppTheme.success : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? 'En línea' : 'Desconectado',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? AppTheme.textLightSecondary
                                    : AppTheme.textDarkSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog();
              } else if (value == 'block') {
                _blockUser();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'report',
                child: ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Reportar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: ListTile(
                  leading: Icon(Icons.block),
                  title: Text('Bloquear'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('Inicia la conversación'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;

                    final currentUserId = _authService.currentUser?.uid;

                    final isMe = message['senderId'] == currentUserId;

                    final messageText = message['message'] as String? ?? '';

                    final imageUrl = message['imageUrl'] as String?;

                    final timestamp = message['timestamp'] as Timestamp?;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        constraints: const BoxConstraints(
                          maxWidth: 280,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isMe ? AppTheme.primaryGradient : null,
                            color: isMe
                                ? null
                                : (isDarkMode
                                    ? AppTheme.darkSurface
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMe ? 20 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDarkMode ? 0.2 : 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      memCacheWidth: 1080,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              if (messageText.isNotEmpty)
                                Text(
                                  messageText,
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : (isDarkMode
                                            ? AppTheme.textLight
                                            : AppTheme.textDark),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),
                              if (timestamp != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatMessageTime(timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isMe
                                              ? Colors.white
                                                  .withValues(alpha: 0.8)
                                              : (isDarkMode
                                                  ? AppTheme.textLightSecondary
                                                  : AppTheme.textDarkSecondary),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          message['read'] == true
                                              ? Icons.done_all_rounded
                                              : Icons.check_rounded,
                                          size: 14,
                                          color: message['read'] == true
                                              ? AppTheme.primaryGreen
                                              : Colors.white
                                                  .withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: _sendingImage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryBlue),
                              ),
                            )
                          : const Icon(
                              Icons.photo_camera,
                              color: AppTheme.primaryBlue,
                            ),
                      onPressed: _sendingImage ? null : _pickAndSendImage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppTheme.darkSurface
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? AppTheme.textLightSecondary
                                : AppTheme.textDarkSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: _sendMessage,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(Timestamp timestamp) {
    final now = DateTime.now();

    final messageTime = timestamp.toDate();

    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${messageTime.day}/${messageTime.month}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();

    super.dispose();
  }
}
