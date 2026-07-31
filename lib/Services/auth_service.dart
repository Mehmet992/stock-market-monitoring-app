import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  bool get isAnonymous => _firebaseAuth.currentUser?.isAnonymous ?? false;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint('[AuthService] Signed up user with email: $email');
      }

      // Send email verification
      await sendEmailVerificationWithRedirect();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (kDebugMode) {
        debugPrint('[AuthService] Signed in user with email: $email');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signInAnonymously() async {
    try {
      await _firebaseAuth.signInAnonymously();
      if (kDebugMode) {
        debugPrint('[AuthService] Signed in anonymously');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendVerificationMail(
      ActionCodeSettings actionCodeSettings,
      ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification(actionCodeSettings);
        if (kDebugMode) {
          debugPrint(
              '[AuthService] Verification email sent to: ${user.email}');
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendEmailVerificationWithRedirect() async {
    final user = _firebaseAuth.currentUser;

    if (user != null && !user.emailVerified) {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://examroadmaptrackerap-49c86e37.firebaseapp.com',

        handleCodeInApp: true,

        iOSBundleId: 'com.example.stockMarketMonitoringApp',

        androidPackageName: 'com.example.stock_market_monitoring_app',
        androidInstallApp: true,
        androidMinimumVersion: '12',
      );

      await sendVerificationMail(actionCodeSettings);
    }
  }

  Future<bool> checkEmailVerified() async {
    final user = _firebaseAuth.currentUser;

    if (user != null) {
      await user.reload();
      final isVerified = _firebaseAuth.currentUser?.emailVerified ?? false;
      if (kDebugMode) {
        debugPrint('[AuthService] Checked email verification: $isVerified');
      }
      return isVerified;
    }

    return false;
  }

  Future<void> linkAnonymousUserWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && user.isAnonymous) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.linkWithCredential(credential);
        if (kDebugMode) {
          debugPrint(
              '[AuthService] Linked anonymous account to email: $email');
        }
        await sendEmailVerificationWithRedirect();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (kDebugMode) {
      debugPrint('[AuthService] User signed out');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      if (kDebugMode) {
        debugPrint('[AuthService] Password reset email sent to: $email');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    if (kDebugMode) {
      debugPrint('[AuthService] Auth error (${e.code}): ${e.message}');
    }
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'user-disabled':
        return 'User account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}

