import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'public_profile_service.dart';

/// Tracks app lifecycle and publishes online presence:
///   users/{uid}:  isOnline, lastActive   (private)
///   profiles/{uid}: isOnline, lastActive (public, shown in chat)
///
/// Register once at app start:
///   WidgetsBinding.instance.addObserver(PresenceService.instance);
/// and call PresenceService.instance.start() after auth is ready.
class PresenceService extends WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final _firestore = FirebaseFirestore.instance;
  Timer? _heartbeat;
  bool _started = false;

  /// Begins heartbeat + marks the user online. Idempotent.
  void start() {
    if (_started) return;
    _started = true;
    _setOnline(true);
    // Refresh lastActive every 2 minutes while the app is foregrounded
    _heartbeat = Timer.periodic(const Duration(minutes: 2), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _setOnline(true);
      }
    });
  }

  void stop() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _started = false;
  }

  /// Public offline marker — called on signOut before auth ends.
  Future<void> setOffline() => _setOnline(false);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _setOnline(false);
        break;
    }
  }

  Future<void> _setOnline(bool online) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('users').doc(uid).update({
        'isOnline': online,
        'lastActive': FieldValue.serverTimestamp(),
      });
      // Keep the public profile in sync (chat reads presence from profiles)
      unawaited(PublicProfileService.sync(uid));
    } catch (e) {
      debugPrint('PresenceService error: $e');
    }
  }
}
