import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/secure_storage_service.dart';
import 'analytics_service.dart';

/// Gestiona invitaciones: detecta el código referido y recompensa al invitador.
class ReferralService {
  static const _referredByKey = 'referred_by';
  static const _appliedKey = 'referral_applied';

  /// Aplica la referencia pendiente si existe. Llamar tras el registro/inicio.
  static Future<void> checkAndApply() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final alreadyApplied = await SecureStorageService.getBool(_appliedKey);
    if (alreadyApplied) return;

    final referrerId = await SecureStorageService.getString(_referredByKey);
    if (referrerId == null || referrerId.isEmpty) return;
    if (referrerId == currentUser.uid) return; // no auto-referirse

    try {
      final firestore = FirebaseFirestore.instance;

      // Registrar la conversión
      await firestore.collection('referrals').add({
        'referrerId': referrerId,
        'referredId': currentUser.uid,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Otorgar 5 likes gratis al invitador
      await firestore.collection('users').doc(referrerId).update({
        'freeLikes': FieldValue.increment(5),
      });

      // Marcar como aplicado
      await SecureStorageService.setBool(_appliedKey, true);

      unawaited(AnalyticsService().logEvent('referral_applied', {
        'referrer_id': referrerId,
        'referred_id': currentUser.uid,
      }));

      debugPrint('Referido aplicado: $referrerId -> ${currentUser.uid}');
    } catch (e) {
      debugPrint('Error aplicando referido: $e');
    }
  }

  /// Genera el enlace de invitación del usuario actual.
  static Future<String> getReferralLink() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return 'https://roommatematch.app/ref/$uid';
  }
}
