import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/secure_logger.dart';

class PermissionValidator {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if current user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Check if user owns a document
  Future<bool> ownsDocument(String collection, String documentId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      SecureLogger.warning('User not authenticated for ownership check');
      return false;
    }

    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      
      if (!doc.exists) {
        SecureLogger.warning('Document does not exist: $collection/$documentId');
        return false;
      }

      final data = doc.data();
      if (data == null) {
        SecureLogger.warning('Document data is null: $collection/$documentId');
        return false;
      }

      // Check for userId field
      final userId = data['userId'] as String?;
      if (userId != null) {
        return userId == currentUser.uid;
      }

      // Check for uid field
      final uid = data['uid'] as String?;
      if (uid != null) {
        return uid == currentUser.uid;
      }

      // Check for ownerId field
      final ownerId = data['ownerId'] as String?;
      if (ownerId != null) {
        return ownerId == currentUser.uid;
      }

      // Check for createdBy field
      final createdBy = data['createdBy'] as String?;
      if (createdBy != null) {
        return createdBy == currentUser.uid;
      }

      SecureLogger.warning('No ownership field found in document: $collection/$documentId');
      return false;
    } catch (e) {
      SecureLogger.error('Error checking document ownership', error: e);
      return false;
    }
  }

  /// Check if user is participant in a document (for chats, matches, etc.)
  Future<bool> isParticipant(String collection, String documentId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      SecureLogger.warning('User not authenticated for participant check');
      return false;
    }

    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      
      if (!doc.exists) {
        SecureLogger.warning('Document does not exist: $collection/$documentId');
        return false;
      }

      final data = doc.data();
      if (data == null) {
        SecureLogger.warning('Document data is null: $collection/$documentId');
        return false;
      }

      // Check for participants array
      final participants = data['participants'] as List?;
      if (participants != null) {
        return participants.contains(currentUser.uid);
      }

      // Check for users array
      final users = data['users'] as List?;
      if (users != null) {
        return users.contains(currentUser.uid);
      }

      // Check for userId field
      final userId = data['userId'] as String?;
      if (userId != null) {
        return userId == currentUser.uid;
      }

      SecureLogger.warning('No participant field found in document: $collection/$documentId');
      return false;
    } catch (e) {
      SecureLogger.error('Error checking participant status', error: e);
      return false;
    }
  }

  /// Check if user has admin role
  Future<bool> isAdmin() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final role = data['role'] as String?;
      return role == 'admin' || role == 'superadmin';
    } catch (e) {
      SecureLogger.error('Error checking admin status', error: e);
      return false;
    }
  }

  /// Check if user has specific role
  Future<bool> hasRole(String requiredRole) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final role = data['role'] as String?;
      return role == requiredRole;
    } catch (e) {
      SecureLogger.error('Error checking user role', error: e);
      return false;
    }
  }

  /// Validate read permission
  Future<PermissionResult> canRead(String collection, String documentId) async {
    if (!isAuthenticated()) {
      return PermissionResult(
        allowed: false,
        reason: 'Usuario no autenticado',
      );
    }

    // Admins can read everything
    if (await isAdmin()) {
      return PermissionResult(allowed: true);
    }

    // Check if user owns the document
    if (await ownsDocument(collection, documentId)) {
      return PermissionResult(allowed: true);
    }

    // Check if user is participant
    if (await isParticipant(collection, documentId)) {
      return PermissionResult(allowed: true);
    }

    return PermissionResult(
      allowed: false,
      reason: 'No tienes permiso para acceder a este documento',
    );
  }

  /// Validate write permission
  Future<PermissionResult> canWrite(String collection, String documentId) async {
    if (!isAuthenticated()) {
      return PermissionResult(
        allowed: false,
        reason: 'Usuario no autenticado',
      );
    }

    // Admins can write everything
    if (await isAdmin()) {
      return PermissionResult(allowed: true);
    }

    // Check if user owns the document
    if (await ownsDocument(collection, documentId)) {
      return PermissionResult(allowed: true);
    }

    return PermissionResult(
      allowed: false,
      reason: 'No tienes permiso para modificar este documento',
    );
  }

  /// Validate delete permission
  Future<PermissionResult> canDelete(String collection, String documentId) async {
    if (!isAuthenticated()) {
      return PermissionResult(
        allowed: false,
        reason: 'Usuario no autenticado',
      );
    }

    // Admins can delete everything
    if (await isAdmin()) {
      return PermissionResult(allowed: true);
    }

    // Check if user owns the document
    if (await ownsDocument(collection, documentId)) {
      return PermissionResult(allowed: true);
    }

    return PermissionResult(
      allowed: false,
      reason: 'No tienes permiso para eliminar este documento',
    );
  }

  /// Validate create permission
  Future<PermissionResult> canCreate(String collection) async {
    if (!isAuthenticated()) {
      return PermissionResult(
        allowed: false,
        reason: 'Usuario no autenticado',
      );
    }

    // Admins can create everything
    if (await isAdmin()) {
      return PermissionResult(allowed: true);
    }

    // Check collection-specific rules
    switch (collection) {
      case 'users':
        return PermissionResult(
          allowed: false,
          reason: 'Los usuarios se crean a través del sistema de autenticación',
        );
      case 'chats':
      case 'matches':
        return PermissionResult(allowed: true);
      case 'reports':
        return PermissionResult(allowed: true);
      case 'swipes':
        return PermissionResult(allowed: true);
      default:
        return PermissionResult(allowed: true);
    }
  }

  /// Check if user can access another user's profile
  Future<PermissionResult> canAccessProfile(String targetUserId) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      return PermissionResult(
        allowed: false,
        reason: 'Usuario no autenticado',
      );
    }

    // Users can always access their own profile
    if (currentUserId == targetUserId) {
      return PermissionResult(allowed: true);
    }

    // Admins can access any profile
    if (await isAdmin()) {
      return PermissionResult(allowed: true);
    }

    // Check if users are matched
    try {
      final matchesQuery = await _firestore
          .collection('matches')
          .where('users', arrayContains: currentUserId)
          .get();

      for (var doc in matchesQuery.docs) {
        final users = doc.data()['users'] as List?;
        if (users != null && users.contains(targetUserId)) {
          return PermissionResult(allowed: true);
        }
      }
    } catch (e) {
      SecureLogger.error('Error checking match status', error: e);
    }

    return PermissionResult(
      allowed: false,
      reason: 'No tienes permiso para acceder a este perfil',
    );
  }

  /// Check if user can send message to another user
  Future<PermissionResult> canSendMessage(String targetUserId) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      return PermissionResult(
        allowed: false,
        reason: 'Usuario no autenticado',
      );
    }

    // Check if users are matched
    try {
      final matchesQuery = await _firestore
          .collection('matches')
          .where('users', arrayContains: currentUserId)
          .get();

      for (var doc in matchesQuery.docs) {
        final users = doc.data()['users'] as List?;
        if (users != null && users.contains(targetUserId)) {
          return PermissionResult(allowed: true);
        }
      }
    } catch (e) {
      SecureLogger.error('Error checking match status for messaging', error: e);
    }

    return PermissionResult(
      allowed: false,
      reason: 'Solo puedes enviar mensajes a usuarios con los que tienes match',
    );
  }

  /// Check if user is blocked
  Future<bool> isBlocked(String targetUserId) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return false;

    try {
      // Check if current user is blocked by target
      final blockedQuery = await _firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: targetUserId)
          .where('blockedId', isEqualTo: currentUserId)
          .get();

      if (blockedQuery.docs.isNotEmpty) {
        return true;
      }

      // Check if target user is blocked by current user
      final blockedByCurrentQuery = await _firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: currentUserId)
          .where('blockedId', isEqualTo: targetUserId)
          .get();

      return blockedByCurrentQuery.docs.isNotEmpty;
    } catch (e) {
      SecureLogger.error('Error checking block status', error: e);
      return false;
    }
  }

  /// Validate permission with automatic error throwing
  Future<void> validateOrThrow(String collection, String documentId, String operation) async {
    PermissionResult result;

    switch (operation.toLowerCase()) {
      case 'read':
        result = await canRead(collection, documentId);
        break;
      case 'write':
        result = await canWrite(collection, documentId);
        break;
      case 'delete':
        result = await canDelete(collection, documentId);
        break;
      case 'create':
        result = await canCreate(collection);
        break;
      default:
        result = PermissionResult(
          allowed: false,
          reason: 'Operación no válida: $operation',
        );
    }

    if (!result.allowed) {
      SecureLogger.security('Permission denied', context: {
        'collection': collection,
        'documentId': documentId,
        'operation': operation,
        'reason': result.reason,
      });
      throw PermissionDeniedException(result.reason ?? 'Permiso denegado');
    }
  }
}

class PermissionResult {
  final bool allowed;
  final String? reason;

  PermissionResult({
    required this.allowed,
    this.reason,
  });
}

class PermissionDeniedException implements Exception {
  final String message;

  PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}
