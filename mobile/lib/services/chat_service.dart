import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'analytics_service.dart';
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

      // Run rate-limit, permission and block checks in parallel
      final permissionValidator = PermissionValidator();
      final (rateLimitResult, permissionResult, isBlocked) = await (
        RateLimiter.canSendMessage(currentUser.uid),
        permissionValidator.canSendMessage(receiverId),
        permissionValidator.isBlocked(receiverId),
      ).wait;

      if (!rateLimitResult.allowed) {
        throw Exception(rateLimitResult.message);
      }
      if (!permissionResult.allowed) {
        throw Exception(permissionResult.reason);
      }
      if (isBlocked) {
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
      final chatRef = _firestore.collection('chats').doc(chatId);

      // Single batch: create/merge chat doc + message + lastMessage update
      // (one network roundtrip instead of 3-4 sequential writes)
      final batch = _firestore.batch();
      batch.set(chatRef, {
        'participants': [currentUser.uid, receiverId],
        'lastMessage': sanitizedMessage,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCounts': {receiverId: FieldValue.increment(1)},
      }, SetOptions(merge: true));
      batch.set(chatRef.collection('messages').doc(), {
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'message': sanitizedMessage,
        'imageUrl': sanitizedImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      await batch.commit();

      // Match doc + push notification are fire-and-forget (don't block the UI)
      unawaited(() async {
        try {
          final matchesQuery = await _firestore
              .collection('matches')
              .where('users', arrayContains: currentUser.uid)
              .get();
          for (var matchDoc in matchesQuery.docs) {
            final users = matchDoc['users'] as List;
            if (users.contains(receiverId)) {
              await matchDoc.reference.update({
                'lastMessage': sanitizedMessage,
                'lastMessageTimestamp': FieldValue.serverTimestamp(),
              });
            }
          }
        } catch (e) {
          debugPrint('Error actualizando match tras mensaje: $e');
        }
      }());

      unawaited(NotificationService()
          .sendChatNotification(
            receiverId,
            senderName: currentUser.displayName ?? 'Alguien',
          )
          .catchError((Object e) => debugPrint('Error enviando notif: $e')));
      unawaited(AnalyticsService().logMessageSent(chatId));
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
  Stream<List<QueryDocumentSnapshot>> getUserChats() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('Usuario no autenticado - devolviendo stream vacío');
      return const Stream<List<QueryDocumentSnapshot>>.empty();
    }

    // Server-side filter: only chats where the user participates
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aTs = a.data()['lastMessageTimestamp'] as Timestamp?;
        final bTs = b.data()['lastMessageTimestamp'] as Timestamp?;
        if (aTs == null || bTs == null) return 0;
        return bTs.compareTo(aTs);
      });
      return docs;
    });
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

      // Single batch instead of one roundtrip per message
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      // Reset unread counter on the chat doc
      batch.set(
        _firestore.collection('chats').doc(chatId),
        {
          'unreadCounts': {currentUser.uid: 0},
        },
        SetOptions(merge: true),
      );
      await batch.commit();
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

      // Prefer the denormalized unreadCounts map maintained on each chat doc.
      // For legacy chats without it, fall back to counting messages (parallel).
      int totalUnread = 0;
      final legacyFutures = <Future<int>>[];

      for (var chatDoc in chatsSnapshot.docs) {
        final counts = chatDoc.data()['unreadCounts'] as Map?;
        if (counts != null) {
          totalUnread += (counts[currentUser.uid] as num?)?.toInt() ?? 0;
        } else {
          legacyFutures.add(_firestore
              .collection('chats')
              .doc(chatDoc.id)
              .collection('messages')
              .where('receiverId', isEqualTo: currentUser.uid)
              .where('read', isEqualTo: false)
              .get()
              .then((s) => s.docs.length));
        }
      }

      if (legacyFutures.isNotEmpty) {
        for (final n in await Future.wait(legacyFutures)) {
          totalUnread += n;
        }
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

      // Delete all messages in batches of 400 (Firestore batch limit is 500)
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var i = 0; i < messages.docs.length; i += 400) {
        final batch = _firestore.batch();
        for (var doc in messages.docs.skip(i).take(400)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
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

  // Get online status (public presence lives in the profiles doc)
  Stream<DocumentSnapshot> getOnlineStatus(String userId) {
    return _firestore.collection('profiles').doc(userId).snapshots();
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
        'status': 'open',
      });
    } catch (e) {
      SecureLogger.error('Failed to report user', error: e);
      rethrow;
    }
  }
}
