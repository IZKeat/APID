// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Central authentication service for handling Google Sign-In and Firebase Auth
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // GoogleSignIn with basic scopes - uses Firebase's built-in Google provider
  // No custom clientId needed - Firebase handles OAuth automatically
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google using Firebase's built-in Google provider
  /// 
  /// This method:
  /// - Triggers Google Sign-In flow
  /// - Retrieves both access token and ID token
  /// - Creates Firebase credential with both tokens
  /// - Signs in to Firebase Auth
  /// 
  /// Returns [UserCredential] on success, null if user cancels
  /// Throws exception on error
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      print(' Starting Google Sign-In flow...');

      // Trigger the Google Sign-In authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        print(' Google Sign-In cancelled by user');
        return null;
      }

      print(' Google user selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential with BOTH accessToken and idToken
      // This is the standard Firebase Google Sign-In flow
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print(' Firebase credential created');

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Firebase sign-in succeeded but user is null');
      }

      print(' Google Sign-In success: ${user.email}');
      print('   UID: ${user.uid}');
      print('   Display Name: ${user.displayName}');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(' Firebase Auth error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print(' Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign out from both Firebase and Google
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      print(' Signed out successfully');
    } catch (e) {
      print(' Sign out error: $e');
      rethrow;
    }
  }

  /// Get current Firebase user
  static User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Change password for the current user
  /// 
  /// Requires re-authentication with [currentPassword] for security.
  /// Then updates the password to [newPassword].
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user is currently signed in.',
        );
      }

      // 1. Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      print(' Re-authentication successful for password change');

      // 2. Update Password
      await user.updatePassword(newPassword);
      print(' Password updated successfully');
      
    } catch (e) {
      print(' Error changing password: $e');
      rethrow;
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print(' Password reset email sent to $email');
    } catch (e) {
      print(' Error sending password reset email: $e');
      rethrow;
    }
  }

  /// Verify the current user's password (re-auth check)
  /// Returns true if valid, false otherwise.
  static Future<bool> verifyPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print(' Password verification failed: $e');
      return false;
    }
  }
}
