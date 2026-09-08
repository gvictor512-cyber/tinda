import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Gestiona roles de administrador para acceso a funciones internas.
class AdminService {
  /// Comprueba si el usuario actual tiene rol admin en Firestore.
  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error comprobando admin: $e');
      return false;
    }
  }
}
