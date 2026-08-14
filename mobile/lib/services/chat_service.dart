import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/input_sanitizer.dart';
import '../utils/permission_validator.dart';
import '../utils/rate_limiter.dart';
import '../utils/secure_logger.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Message limit for chat history
  static const int MESSAGE_LIMIT = 50;

  // Typing status timeout in seconds
  static const int TYPING_STATUS_TIMEOUT_SECONDS = 3;

  // Get chat ID for two users
  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String message,
    String? imageUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        SecureLogger.warning('Unauthenticated message send attempt');
        throw Exception('Usuario no autenticado');
      }

      // Check rate limiting
      final rateLimitResult = await RateLimiter.canSendMessage(currentUser.uid);
      if (!rateLimitResult.allowed) {
        throw Exception(rateLimitResult.message);
      }

      // Check permissions
      final permissionValidator = PermissionValidator();
      final permissionResult = await permissionValidator.canSendMessage(receiverId);
      if (!permissionResult.allowed) {
        throw Exception(permissionResult.reason);
      }

      // Check if blocked
      if (await permissionValidator.isBlocked(receiverId)) {
        throw Exception('No puedes enviar mensajes a este usuario');
      }

      // Sanitize message
      final sanitizedMessage = InputSanitizer.sanitizeString(message);
      if (sanitizedMessage.isEmpty && imageUrl == null) {
        throw Exception('El mensaje no puede estar vacío');
      }

      // Limit message length
      if (sanitizedMessage.length > 1000) {
        throw Exception('El mensaje es demasiado largo (máximo 1000 caracteres)');
      }

      // Sanitize image URL if provided
      String? sanitizedImageUrl;
      if (imageUrl != null) {
        sanitizedImageUrl = InputSanitizer.sanitizeUrl(imageUrl);
      }

      SecureLogger.debug('Sending message', data: {
        'sender': currentUser.uid,
        'receiver': receiverId,
        'hasImage': imageUrl != null,
      });

      final chatId = _getChatId(currentUser.uid, receiverId);

      // Check if chat exists, if not create it
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [currentUser.uid, receiverId],
          'lastMessage': message,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSender': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Add message
      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'message': sanitizedMessage,
        'imageUrl': sanitizedImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update chat document
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': sanitizedMessage,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUser.uid,
      });

      // Update match document
      final matchesQuery = await _firestore
          .collection('matches')
          .where('users', arrayContains: currentUser.uid)
          .get();

      for (var matchDoc in matchesQuery.docs) {
        final users = matchDoc['users'] as List;
        if (users.contains(receiverId)) {
          await _firestore.collection('matches').doc(matchDoc.id).update({
            'lastMessage': message,
            'lastMessageTimestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      SecureLogger.error('Failed to send message', error: e, data: {
        'sender': _auth.currentUser?.uid,
        'receiver': receiverId,
      });
      rethrow;
    }
  }

  // Get messages for a chat
  Stream<QuerySnapshot> getMessages(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('Usuario no autenticado - devolviendo stream vacío');
      return const Stream.empty();
    }

    final chatId = _getChatId(currentUser.uid, otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(MESSAGE_LIMIT)
        .snapshots();
  }

  // Get all chats for current user
  Stream<QuerySnapshot> getUserChats() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('Usuario no autenticado - devolviendo stream vacío');
      return const Stream.empty();
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - no se pueden marcar mensajes como leídos');
        return;
      }

      final chatId = _getChatId(currentUser.uid, otherUserId);

      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'read': true});
      }
    } catch (e) {
      debugPrint('Error al marcar mensajes como leídos: $e');
      rethrow;
    }
  }

  // Get unread message count
  Future<int> getUnreadCount(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - devolviendo 0 mensajes no leídos');
        return 0;
      }

      final chatId = _getChatId(currentUser.uid, otherUserId);

      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('read', isEqualTo: false)
          .get();

      return unreadMessages.docs.length;
    } catch (e) {
      debugPrint('Error al obtener contador de mensajes no leídos: $e');
      return 0;
    }
  }

  // Get total unread count across all chats
  Future<int> getTotalUnreadCount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - devolviendo 0 total de mensajes no leídos');
        return 0;
      }

      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      int totalUnread = 0;

      for (var chatDoc in chatsSnapshot.docs) {
        final chatId = chatDoc.id;
        final unreadMessages = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('receiverId', isEqualTo: currentUser.uid)
            .where('read', isEqualTo: false)
            .get();

        totalUnread += unreadMessages.docs.length;
      }

      return totalUnread;
    } catch (e) {
      debugPrint('Error al obtener total de mensajes no leídos: $e');
      return 0;
    }
  }

  // Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint('Error al eliminar mensaje: $e');
      rethrow;
    }
  }

  // Delete chat
  Future<void> deleteChat(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Usuario no autenticado');

      final chatId = _getChatId(currentUser.uid, otherUserId);

      // Delete all messages
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Delete chat document
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      debugPrint('Error al eliminar chat: $e');
      rethrow;
    }
  }

  // Get typing status
  Stream<DocumentSnapshot> getTypingStatus(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('Usuario no autenticado - devolviendo stream vacío');
      return const Stream.empty();
    }

    final chatId = _getChatId(currentUser.uid, otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(otherUserId)
        .snapshots();
  }

  // Set typing status
  Future<void> setTypingStatus(String otherUserId, bool isTyping) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - no se puede establecer estado de escritura');
        return;
      }

      final chatId = _getChatId(currentUser.uid, otherUserId);

      if (isTyping) {
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('typing')
            .doc(currentUser.uid)
            .set({
          'isTyping': true,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Auto-remove after timeout
        Future.delayed(const Duration(seconds: TYPING_STATUS_TIMEOUT_SECONDS), () {
          _firestore
              .collection('chats')
              .doc(chatId)
              .collection('typing')
              .doc(currentUser.uid)
              .delete();
        });
      } else {
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('typing')
            .doc(currentUser.uid)
          .delete();
      }
    } catch (e) {
      debugPrint('Error al establecer estado de escritura: $e');
      rethrow;
    }
  }

  // Get online status
  Stream<DocumentSnapshot> getOnlineStatus(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Send image message
  Future<void> sendImageMessage({
    required String receiverId,
    required String imageUrl,
    String? caption,
  }) async {
    await sendMessage(
      receiverId: receiverId,
      message: caption ?? '',
      imageUrl: imageUrl,
    );
  }

  // Block user
  Future<void> blockUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        SecureLogger.warning('Unauthenticated block attempt');
        throw Exception('Usuario no autenticado');
      }

      // Validate user ID
      if (userId.isEmpty || userId == currentUser.uid) {
        throw Exception('ID de usuario inválido');
      }

      SecureLogger.security('User blocked', context: {
        'blocker': currentUser.uid,
        'blocked': userId,
      });

      await _firestore.collection('blocked_users').add({
        'blockerId': currentUser.uid,
        'blockedId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      SecureLogger.error('Failed to block user', error: e);
      rethrow;
    }
  }

  // Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - devolviendo false para verificación de bloqueo');
        return false;
      }

      final blockedQuery = await _firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: currentUser.uid)
          .where('blockedId', isEqualTo: userId)
          .get();

      return blockedQuery.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error al verificar si el usuario está bloqueado: $e');
      return false;
    }
  }

  // Unblock user
  Future<void> unblockUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - no se puede desbloquear usuario');
        return;
      }

      final blockedQuery = await _firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: currentUser.uid)
          .where('blockedId', isEqualTo: userId)
          .get();

      for (var doc in blockedQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error al desbloquear usuario: $e');
      rethrow;
    }
  }

  // Report user
  Future<void> reportUser({
    required String userId,
    required String reason,
    String? description,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        SecureLogger.warning('Unauthenticated report attempt');
        throw Exception('Usuario no autenticado');
      }

      // Check rate limiting for reports
      final rateLimitResult = await RateLimiter.canReport(currentUser.uid);
      if (!rateLimitResult.allowed) {
        throw Exception(rateLimitResult.message);
      }

      // Validate inputs
      if (userId.isEmpty || userId == currentUser.uid) {
        throw Exception('ID de usuario inválido');
      }

      if (reason.isEmpty) {
        throw Exception('La razón del reporte es requerida');
      }

      // Sanitize inputs
      final sanitizedReason = InputSanitizer.sanitizeString(reason);
      final sanitizedDescription = description != null 
          ? InputSanitizer.sanitizeBio(description) 
          : null;

      SecureLogger.security('User reported', context: {
        'reporter': currentUser.uid,
        'reported': userId,
        'reason': sanitizedReason,
      });

      await _firestore.collection('reports').add({
        'reporterId': currentUser.uid,
        'reportedId': userId,
        'reason': sanitizedReason,
        'description': sanitizedDescription,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      SecureLogger.error('Failed to report user', error: e);
      rethrow;
    }
  }
}
