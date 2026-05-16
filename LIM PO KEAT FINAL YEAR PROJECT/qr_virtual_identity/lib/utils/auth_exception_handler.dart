import 'package:firebase_auth/firebase_auth.dart';

class AuthExceptionHandler {
  /// Map Firebase Auth error codes to user-friendly messages
  static String handleException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Account not found. Please check your email or sign up.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Login with this method is not allowed.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'credential-already-in-use':
          return 'This credential is already associated with a different user account.';
        default:
          return 'Authentication failed: ${e.message ?? "Unknown error"}';
      }
    } else {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }
}
