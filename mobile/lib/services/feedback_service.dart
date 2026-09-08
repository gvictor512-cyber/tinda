import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Envía sugerencias y reportes de bugs a Firestore.
class FeedbackService {
  static Future<void> submit({
    required String message,
    String type = 'suggestion',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'message': message,
        'type': type,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'open',
      });
    } catch (e) {
      debugPrint('Error enviando feedback: $e');
      rethrow;
    }
  }
}
