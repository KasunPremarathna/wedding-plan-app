import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// User Model for local state
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthNotifier() : super(const AsyncValue.data(null)) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _googleSignIn.signInSilently();
      if (user != null) {
        _updateFCMToken(user.id);
        state = AsyncValue.data(AppUser(
          id: user.id,
          name: user.displayName ?? 'User',
          email: user.email,
          photoUrl: user.photoUrl,
        ));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _googleSignIn.signIn();
      if (user != null) {
        _updateFCMToken(user.id);
        state = AsyncValue.data(AppUser(
          id: user.id,
          name: user.displayName ?? 'User',
          email: user.email,
          photoUrl: user.photoUrl,
        ));
      } else {
        // User canceled sign in
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _googleSignIn.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _updateFCMToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcm_token': token,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Also update vendor document if they are a vendor (ignore if not found using merge)
        await FirebaseFirestore.instance.collection('vendor_registrations').doc(userId).set({
          'fcm_token': token,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Ignore FCM update errors silently
    }
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier();
});
